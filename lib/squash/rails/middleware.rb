module Squash
  module Rails
    class Middleware

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
          @env['squash.notified'] = ::Squash::Ruby.notify(ex)
          raise ex
        end

        result
      end

    end
  end
end

