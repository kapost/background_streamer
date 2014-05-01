require 'logger'

module BackgroundStreamer

  class << self
    def logger
      return @logger if defined?(@logger)
      @logger = rails_logger || default_logger
    end

    def logger=(logger)
      @logger = logger
    end

    def rails_logger
      defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
    end

    def default_logger
      return @default_logger if defined?(@default_logger)

      @default_logger = Logger.new(STDOUT)
      @default_logger.level = Logger::INFO
      @default_logger
    end
  end
end

require "background_streamer/version"
require 'background_streamer/manager'
require 'background_streamer/worker'
require 'background_streamer/helper'
