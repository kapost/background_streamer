# BackgroundStreamer

Allows you to use a thread pool to process streaming of long running requests. This helps you get around
the timout limits that unicorn places on a request.

## Installation

Add this line to your application's Gemfile:

    gem 'background_streamer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install background_streamer

## Usage

    require 'background_streamer'
    
    class BulkController < ApplicationController
      include BackgroundStreamer::Helper
    
      create_stream_manager :stream

      def query       
        # We don't want Rack::Cache doing anything crazy
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s

        if env['rack.hijack']
          perform_hijack
        else
          self.response_body = get_all
        end
      end

      private

      def perform_hijack    
        env['rack.hijack'].call
        io = env['rack.hijack_io']

        stream << BackgroundStreamer::Worker.new(env, 200, {"X-Request-Id" => env['X_REQUEST_ID']}, get_all, io)
        self.response_body = []
      end

      def get_all
        1.upto(100).each {|i| i}
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
