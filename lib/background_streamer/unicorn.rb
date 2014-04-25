# Monkey path for unicorn to allow a rack 1.4 app to use hijack
# Require it in your unicorn.rb
unless ((Rack::VERSION[0] << 8) | Rack::VERSION[1]) >= 0x0102
  class ::Unicorn::HttpParser
    DEFAULTS["rack.hijack?"] = true

    RACK_HIJACK = "rack.hijack".freeze
    RACK_HIJACK_IO = "rack.hijack_io".freeze

    def hijacked?
      env.include?(RACK_HIJACK_IO)
    end

    def hijack_setup(e, socket)
      e[RACK_HIJACK] = proc { e[RACK_HIJACK_IO] = socket }
    end
  end
end
