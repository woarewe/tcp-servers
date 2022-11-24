#!/usr/bin/env ruby

require 'socket'

server = TCPServer.new 2000

LIMIT = 20_000
BYTES = 10 * 1024

count = 0

loop do
  connection = server.accept
  count += 1
  connection.read(BYTES)
  data = File.read(File.expand_path('./data.txt', __dir__))
  connection.write(data)
  connection.close
  puts count
  break if count == LIMIT
end
