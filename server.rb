#!/usr/bin/env ruby

require 'socket'
require 'logger'

PORT = 2000
LIMIT = 1_000
BYTES = 100 * 1024 * 1024

class Server
  attr_reader :port, :server, :logger

  def initialize(port)
    @port = port
    @server = TCPServer.new(port)
    @requests = 0
    @logger = Logger.new($stdout)
  end
end

class Serial < Server
  def start
    loop do
      handle_request(server.accept)
      @requests += 1
      logger.info(@requests)
    end
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
end

server.start
