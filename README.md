# BackgroundStreamer

Allows you to use a thread to process streaming of long running requests. This helps you get around
the timout limits that unicorn places on a request.

## Installation

Add this line to your application's Gemfile:

    gem 'background_streamer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install background_streamer

## Usage

```ruby
require 'background_streamer'

class BulkController < ApplicationController
  def query       
    # We don't want Rack::Cache doing anything crazy
    self.response.headers['Last-Modified'] = Time.now.ctime.to_s

    if env['rack.hijack']
      BackgroundStreamer::Worker.perform_async(env, get_all, timeout: 5)
      self.response_body = []
    else
      self.response_body = get_all
    end
  end

  private

  def get_all
    1.upto(100).each { |i| i }
  end
end
```

### Configuration

Background streamer provides several configuration options that your app can leverage.

* `logger`: Define a custom logger. *(defaults to a `Logger.new(STDOUT)`)*
* `max_threads`: Define the thread limit for number of background streams. *(defaults to 50)*
* `on_worker_exit`: Define a handler for thread unload logic, useful for closing active database
  connections and the like. *(defaults to `nil`)*

```ruby
BackgroundStreamer.configure do |config|
  config.logger = Rails.logger

  config.max_threads = 100

  config.on_worker_exit = proc do
    ActiveRecord::Base.connection.disconnect!
  end
end
```

### Error Handling

It is possible for `BackgroundStreamer::Worker.perform_async` to raise an error if the `max_thread`
limit is reached.  Your application should be prepared to handle
`BackgroundStreamer::ThreadLimitExceeded`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
