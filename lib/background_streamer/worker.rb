require 'rack'
require 'timeout'

module BackgroundStreamer
  class Worker
    CRLF = "\r\n".freeze
    RACK_HIJACK = 'rack.hijack'.freeze
    RACK_HIJACK_IO = 'rack.hijack_io'.freeze
    ACTION_DISPATCH_REQUEST_ID = 'action_dispatch.request_id'.freeze
    X_REQUEST_ID = 'X_REQUEST_ID'.freeze

    attr_reader :options, :timeout, :request_id, :status, :headers, :io, :body

    class << self
      def perform_async(env, body, options = {})
        env[RACK_HIJACK].call

        threads.keep_if(&:alive?)

        if threads.size >= BackgroundStreamer.max_threads
          raise ThreadLimitExceeded, "Thread limit of #{BackgroundStreamer.max_threads} exceeded"
        end

        threads << Thread.new do
          worker = new(env, body, options)
          worker.perform

          BackgroundStreamer.on_worker_exit.call if BackgroundStreamer.on_worker_exit
        end
      end

      private

      def threads
        @threads ||= []
      end
    end
      
    def initialize(env, body, options = {})
      @io         = env[RACK_HIJACK_IO]
      @request_id = env[ACTION_DISPATCH_REQUEST_ID] || env[X_REQUEST_ID]
      @options    = options
      @timeout    = @options.delete(:timeout) || 15.seconds

      app = -> _ { [200, create_headers, body] }
      @status, @headers, @body = Rack::Deflater.new(app).call(env)
    end

    def perform
      logger.push_tags("#{self.class.name}.#{request_id}") if logger.respond_to?(:push_tags)
      now = Time.now
      logger.info "Starting ..."
      
      stream
    ensure
      close
      logger.info "Finished in #{Time.now - now} seconds."
      logger.pop_tags if logger.respond_to?(:pop_tags)
    end

    private

    def stream
      write_headers

      Timeout::timeout(timeout) do
        logger.debug "Writing Body"

        body.each do |chunk|
          write_chunk chunk
        end
      end
    rescue => e
      logger.warn "Streaming has failed: #{e} => #{e.backtrace}"
    ensure
      write_chunk ""
    end

    def close
      logger.debug "Closing connection"

      unless io.closed?
        io.shutdown # in case of fork() in Rack app
        io.close # flush and uncork socket immediately, no keepalive
      end
    rescue => e
      logger.info "Closing connection failed: #{e} => #{e.backtrace}"
    end

    def write_chunk(chunk)
      io << [chunk.size.to_s(16), CRLF, chunk, CRLF].join
    end

    def create_headers
      {
        "Date"              => Time.now.strftime("%a %e %b %T %Y %Z"),
        "Status"            => "200 OK",
        "Connection"        => "close",
        "Content-Type"      => "application/json; charset=utf-8",
        "Cache-Control"     => "max-age=0, private, no-cache",
        "Transfer-Encoding" => "chunked",
        "X-Request-Id"      => request_id, 
      }
    end

    def write_headers
      logger.debug "Writing Headers"

      buffer = ""
      buffer << "HTTP/1.1 200 OK" << CRLF

      headers.each do |key, value|
        buffer << "#{key}: #{value}#{CRLF}"
      end

      buffer << CRLF

      io << buffer
    end

    def logger
      BackgroundStreamer.logger
    end
  end
end
