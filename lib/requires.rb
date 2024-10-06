require "set"
require "benchmark"

STDOUT.sync = true # DO NOT REMOVE

# @param log_level [Integer] the lower, the more priority. [0=debug, 1=warn, 2=info]
def debug(message, log_level = 2)
  STDERR.puts(message) if log_level <= 2
end
