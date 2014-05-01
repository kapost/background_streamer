require 'rack'
require 'timeout'

module BackgroundStreamer
  class Worker
    CRLF= "\r\n".freeze

    @count = 0
    @middleware = []

    class << self
      attr_accessor :count
      attr_accessor :middleware
      def inc
        @count += 1
      end

      def use middleware
        @middleware << middleware
      end
    end

    use Rack::Deflater

    def initialize(env, status, headers, body, io)
      @job_id = self.class.inc
      @io = io
      @request_id = env["action_dispatch.request_id"]

      @status, @headers, @body = create_app(status, headers, body, env)
    end

    def process(options = {})
      if logger.respond_to?(:push_tags)
        logger.push_tags(@request_id) if @request_id
        logger.push_tags("streamer.#{@job_id}")
      end

      @options = options

      now = Time.now

      info { "Starting." }
      stream
    ensure
      close
      info {"Finished in #{Time.now - now} seconds."}

      if logger.respond_to?(:pop_tags)
        logger.pop_tags
        logger.pop_tags if @request_id
      end
    end

    private

    def create_app status, headers, body, env
      app = -> _ {[status, create_headers(headers), body]}
      self.class.middleware.each do |middleware|
        app = middleware.new(app)
      end

      app.call(env)
    end

    def stream
      write_headers

      Timeout::timeout(@options[:timeout] || 15.seconds) do
        debug {"Writing Body"}
        @body.each do |chunk|
          write_chunk chunk
        end
      end
    rescue Timeout::Error => e
      warn{"Timeout limit reached."}
      write_chunk "TIMEOUT!#{CRLF}"
    rescue => e
      warn{"Streaming has failed: #{e} => #{e.backtrace}"}
      raise
    ensure
      write_chunk ""
    end

    def close
      debug{"Closing connection"}
      unless @io.closed?
        @io.shutdown # in case of fork() in Rack app
        @io.close # flush and uncork socket immediately, no keepalive
      end
    rescue => e
      info{"Closing connection failed: #{e} => #{e.backtrace}"}
    end

    def write_chunk chunk
      @io << [chunk.size.to_s(16), CRLF, chunk, CRLF].join
    end

    def create_headers headers
      headers = {
        "Date" => Time.now.strftime("%a %e %b %T %Y %Z"),
        "Status" => "200 OK",
        "Connection" => "close",
        "Content-Type" => "application/json; charset=utf-8",
        "Cache-Control" => "max-age=0, private, no-cache",
        "Transfer-Encoding" => "chunked"
      }.merge!(headers)
    end

    def write_headers
      debug {"Writing Headers"}

      buffer = ""
      buffer << "HTTP/1.1 200 OK" << CRLF
      @headers.each do |key, value|
        buffer << "#{key}: #{value}#{CRLF}"
      end

      buffer << CRLF

      @io << buffer
    end

    def logger
      BackgroundStreamer.logger
    end

    def debug
      logger.debug {yield}
    end

    def info
      logger.info {yield}
    end

    def warn
      logger.warn {yield}
    end

    def error
      logger.error {yield}
    end
  end
end