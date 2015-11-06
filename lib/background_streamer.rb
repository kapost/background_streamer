require 'logger'

module BackgroundStreamer
  class << self
    attr_accessor :on_worker_exit

    def configure
      yield self
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def logger=(logger)
      @logger = logger
    end

    def max_threads
      @max_threads ||= 50
    end

    def max_threads=(val)
      @max_threads = val
    end
  end
end

require 'background_streamer/version'
require 'background_streamer/errors'
require 'background_streamer/worker'
