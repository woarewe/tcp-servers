#!/usr/bin/env ruby

require 'socket'

server = TCPServer.new 2000

LIMIT = 20_000
BYTES = 10 * 1024

count = 0

GC::Profiler.enable

loop do
  connection = server.accept
  count += 1
  connection.read(BYTES)
  data = File.read(File.expand_path('./data.txt', __dir__))
  connection.write(data)
  connection.close
  break if count == LIMIT
end

GC::Profiler.report

GC::Profiler.disable
