#!/usr/bin/env ruby

require 'socket'

REQUESTS_NUMBER = 10_000
CORES_NUMBER = 10

TASKS_PER_WORKER = (REQUESTS_NUMBER / CORES_NUMBER).freeze
before = Time.now

workers = Array.new(CORES_NUMBER) do |i|
  Ractor.new do
    requests = Ractor.receive
    requests.times do
      connection = TCPSocket.new 'localhost', 2000
      connection.puts("Message")
      connection.gets
      connection.close
    end
  end
end

workers.each do |worker|
  worker.send(TASKS_PER_WORKER)
end

workers.each(&:take)

puts "Took: #{after.to_i - before.to_i}"
