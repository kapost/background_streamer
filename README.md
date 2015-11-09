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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
