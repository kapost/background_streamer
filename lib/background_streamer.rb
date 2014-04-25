require 'logger'

module BackgroundStreamer
  if defined?(Rails)
    @logger = Rails.logger
  end

  @logger ||= Logger.new(STDERR)

  class << self
    attr_accessor :logger
  end
end

require "background_streamer/version"
require 'background_streamer/manager'
require 'background_streamer/worker'
require 'background_streamer/helper'