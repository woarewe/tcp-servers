def time
  before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  result = yield
  after = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts after - before
  result
end
