#!/usr/bin/env ruby

require 'socket'

REQUESTS_NUMBER = 20_000
CORES_NUMBER = 10

TASKS_PER_WORKER = (REQUESTS_NUMBER / CORES_NUMBER).freeze

before = Process.clock_gettime(Process::CLOCK_MONOTONIC)

BYTES = 10 * 1024
MESSAGE = "*" * BYTES

# CORES_NUMBER.times do
#   Process.fork do
#     TASKS_PER_WORKER.times do
#       connection = TCPSocket.new 'localhost', 2000
#       connection.puts "Message"
#       puts connection.gets
#       connection.close
#     end
#   end
# end
#
# Process.waitall

REQUESTS_NUMBER.times do
  connection = TCPSocket.new 'localhost', 2000
  connection.write(MESSAGE)
  connection.read(BYTES)
end

after = Process.clock_gettime(Process::CLOCK_MONOTONIC)

puts "Took: #{after - before}"
