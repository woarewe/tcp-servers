#!/usr/bin/env ruby

require 'socket'
require 'logger'
require 'concurrent-ruby'

PORT = 2000
LIMIT = 1_000
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


server = case ARGV[0]
when 'serial' then Serial.new(PORT)
when 'thread-pool' then ThreadPool.new(PORT)
when 'custom-thread-pool' then CustomThreadPool.new(PORT)
end

server.start
