module BackgroundStreamer
  class Manager

    def initialize(opts = {})
      @options = {
        :timeout => opts[:timeout]
      }
      @started = false
      @started_mutex = Mutex.new
    end

    def enqueue_work work
      start_workers
      @work_queue << work
    end

    def << work
      enqueue_work work
    end

    def end_workers
      @workers.each do
        @work_queue << :stop
      end

      @workers.each do |worker|
        worker.join
        yield worker if block_given?
      end

      @workers = []
    end

    private

    def start_workers options = {}
      @started_mutex.synchronize do
        return if @started

        @workers = []
        @work_queue = SizedQueue.new (options[:queue_size] || 50)

        (options[:number_of_workers] || 5).times do |worker|
          debug{"Starting worker #{worker}"}
          @workers << Thread.new do
            loop do
              job = @work_queue.pop

              break if job === :stop

              process_job(job)
            end
          end
        end

        @started = true
      end
    end

    def process_job work
      work.process(@options) if work && work.respond_to?(:process)
    rescue => ex
      error{"Processing failed: #{ex} => #{ex.backtrace}"}    
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