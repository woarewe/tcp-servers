#!/usr/bin/env ruby

require 'socket'
require 'logger'
require 'concurrent-ruby'

PORT = 2000
BYTES = 100 * 1024 * 1024
CORES_NUMBER = 10

class Server
  attr_reader :port, :server, :logger

  def initialize(port)
    @port = port
    @server = TCPServer.new(port)
    @requests = 0
  end

  def count_request
    @requests += 1
  end

  def requests
    @requests
  end
end

class Serial < Server
  def start
    logger = Logger.new($stdout)
    loop do
      handle_request(server.accept)
      count_request
      logger.info(requests)
    end
  end

  def handle_request(connection)
    connection.read(BYTES)
    data = File.read(File.expand_path('./data.txt', __dir__))
    connection.write(data)
    connection.close
  end
end

class ThreadPool < Server
  def start
    logger = Logger.new($stdout)
    workers = Concurrent::FixedThreadPool.new(CORES_NUMBER)
    loop do
      handle_request(workers, server.accept)
      count_request
      logger.info(requests)
    end
  end

  def handle_request(workers, connection)
    workers.post do
      connection.read(BYTES)
      data = File.read(File.expand_path('./data.txt', __dir__))
      connection.write(data)
      connection.close
    end
  end
end

class CustomThreadPool < Server
  def start
    logger = Logger.new($stdout)
    workers = Array.new(CORES_NUMBER) do
      Thread.new do
        loop do
          handle_request(server.accept)
          count_request
          logger.info(requests)
        end
      end
    end
    workers.each(&:join)
  end

  def handle_request(connection)
    connection.read(BYTES)
    data = File.read(File.expand_path('./data.txt', __dir__))
    connection.write(data)
    connection.close
  end
end

class CustomFiber < Server
  attr_reader :tasks

  def initialize(...)
    super(...)
    @tasks = []
    @logger = Logger.new($stdout)
  end

  def start
    loop do
      connection = server.accept_nonblock
      task = handle_connection(connection)
      tasks.push(task)
    rescue IO::WaitReadable, IO::EAGAINWaitReadable => error
      handle_nonblock_accept
      retry
    end
  end

  private

  def handle_nonblock_accept
    task = tasks.pop
    if task.nil?
      IO.select([server])
      return
    end

    result = task.resume
    case result
    when :writing, :reading
      tasks.push(task)
    end
  end

  def handle_connection(connection)
    Fiber.new do
      nonblocking_read(connection, BYTES)
      file = File.new(File.expand_path('./data.txt', __dir__))
      data = nonblocking_read(file, BYTES)
      nonblocking_write(connection, data)
      connection.close
      count_request
      nonblocking_write($stdout, "#{requests}\n")
      :done
    end
  end

  def nonblocking_read(io, size, buffer = '')
    batch = io.read_nonblock(size)
    remaining_size = size - batch.bytesize
    result = buffer + batch
    return result if remaining_size.zero?

    nonblocking_read(io, remaining_size, result)
  rescue IO::WaitReadable, IO::EAGAINWaitReadable
    Fiber.yield :reading
    retry
  end

  def nonblocking_write(io, data)
    written_size = io.write_nonblock(data)

    return if written_size == data.bytesize
    # TODO: Use IO::Buffer to optimize splitting bytes
    nonblocking_write(io, data.slice!(0, written_size))
  rescue IO::WaitWritable
    Fiber.yield :writing
    retry
  end

  def read_file
    file = File.new(File.expand_path('./data.txt', __dir__))
    file.read_nonblock(BYTES)
  rescue IO::WaitReadable, IO::EAGAINWaitReadable
    Fiber.yield :reading
    retry
  end
end


server = case ARGV[0]
when 'serial' then Serial.new(PORT)
when 'thread-pool' then ThreadPool.new(PORT)
when 'custom-thread-pool' then CustomThreadPool.new(PORT)
when 'custom-fiber' then CustomFiber.new(PORT)
end

server.start
