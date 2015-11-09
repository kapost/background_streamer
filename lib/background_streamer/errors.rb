module BackgroundStreamer
  class Error < StandardError; end
  class ThreadLimitExceeded < Error; end
end
