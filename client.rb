#!/usr/bin/env ruby

require 'socket'

REQUESTS_NUMBER = 1_000
CORES_NUMBER = 10

TASKS_PER_WORKER = (REQUESTS_NUMBER / CORES_NUMBER).freeze

before = Process.clock_gettime(Process::CLOCK_MONOTONIC)

BYTES = 100 * 1024 * 1024
MESSAGE = "*" * BYTES

CORES_NUMBER.times do
  Process.fork do
    TASKS_PER_WORKER.times do
      connection = TCPSocket.new 'localhost', 2000
      connection.write(MESSAGE)
      connection.read(BYTES)
      connection.close
    end
  end
end

Process.waitall

after = Process.clock_gettime(Process::CLOCK_MONOTONIC)

puts "Took: #{after - before}"
