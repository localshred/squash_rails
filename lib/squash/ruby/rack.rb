module Squash
  module Ruby
    class Rack

      def initialize(app)
        @app = app
      end

      # Rescue any exceptions thrown downstream, notify Squash, then
      # re-raise them.
      #
      def call(env)
        @env = env

        begin
          result = @app.call(env)
        rescue ::Exception => ex
          @env['squash.notified'] = ::Squash::Ruby.notify(ex, squash_rack_data)
          raise ex
        end

        result
      end

      # @abstract
      #
      # Override this method to implement filtering of sensitive data in the
      # `params`, `session`, `flash`, and `cookies` hashes before they are
      # transmitted to Squash. The `params` hash is already filtered according to
      # the project's `filter_parameters` configuration option; if you need any
      # additional filtering, override this method.
      #
      # @param [Hash] data The hash of user data to be filtered.
      # @param [Symbol] kind Either `:params`, `:session`, `:flash`, `:cookies`, or
      #   `:headers`.
      # @return [Hash] A copy of `data` with sensitive data removed or replaced.

      def filter_for_squash(data, kind)
        data
      end

      # @return [Hash<Symbol, Object>] The additional information that
      #   {#notify_squash} gives to `Squash::Ruby.notify`.

      def squash_rack_data
        {
          :environment    => environment_name,
          :root           => root_path,
          :request_method => @env['REQUEST_METHOD'].to_s.upcase,
          :schema         => @env['rack.url_scheme'],
          :host           => @env['SERVER_NAME'],
          :port           => @env['SERVER_PORT'],
          :path           => @env['PATH_INFO'],
          :query          => @env['QUERY_STRING'],
          :headers        => filter_for_squash(request_headers, :headers),
          :cookies        => filter_for_squash(@env['rack.request.cookie_hash'], :cookies)
        }
      end

      private

      def environment_name
        if defined?(Rails)
          Rails.env
        else
          ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'unknown'
        end
      end

      # Extract any rack key/value pairs where the key begins with HTTP_*
      #
      def request_headers
        @env.select { |key, value| key =~ /^HTTP_/ }
      end

      def root_path
        if defined?(Rails)
          Rails.root.to_s
        else
          'unknown'
        end
      end

    end
  end
end

