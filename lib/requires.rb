require "set"
require "benchmark"

STDOUT.sync = true # DO NOT REMOVE
LOG_LEVEL = 0 # as in OFF

# @param log_level [Integer] the lower, the more priority. [0=off, 1=everything, 2=core, 3=timing]
def debug(message, relevance = 1)
  return if LOG_LEVEL.zero?

  STDERR.puts(message) if relevance >= LOG_LEVEL
end

# @param time [Float] seconds strsight from Benchmark.relatime
def report_time(time, message)
  return if time < 0.01 # as in 10ms

  debug("Took #{(time * 1000).round}ms to #{message}", 3)
end
