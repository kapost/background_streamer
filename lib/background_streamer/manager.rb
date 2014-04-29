module BackgroundStreamer
  class Manager

    def initialize(opts = {})
      debug {"Creating"}
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

    def debug
      BackgroundStreamer.logger.debug {"[PID: #{$$}] Stream Manager: #{yield}"}
    end

    def info
      BackgroundStreamer.logger.info {"[PID: #{$$}] Stream Manager: #{yield}"}
    end

    def warn
      BackgroundStreamer.logger.warn {"[PID: #{$$}] Stream Manager: #{yield}"}
    end

    def error
      BackgroundStreamer.logger.error {"[PID: #{$$}] Stream Manager: #{yield}"}
    end
  end
end