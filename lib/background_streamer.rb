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
  end
end

require "background_streamer/version"
require 'background_streamer/worker'
