module Pushr
  module Daemon
    module GcmSupport
      class ConnectionError < StandardError; end

      class ConnectionGcm
        attr_reader :response, :name, :configuration
        PUSH_URL = 'https://android.googleapis.com/gcm/send'
        IDLE_PERIOD = 5 * 60

        def initialize(configuration, i)
          @configuration = configuration
          @name = "#{@configuration.app}: ConnectionGcm #{i}"
        end

        def connect
          @last_use = Time.now
          uri = URI.parse(PUSH_URL)
          @connection = open_http(uri.host, uri.port)
          @connection.start
          Pushr::Daemon.logger.info("[#{@name}] Connected to #{PUSH_URL}")
        end

        def write(data)
          retry_count = 0
          begin
            response = notification_request(data.to_message)
            handle_response(response, data, retry_count)
          rescue => e
            retry_count += 1
            if retry_count < 10
              retry
            else
              raise e
            end
          end
        end

        private

        def handle_response(response, data, retry_count)
          if response.code.eql? '200'
            handler = Pushr::Daemon::GcmSupport::ResponseHandler.new(response, data)
            handler.handle
          else
            handle_error_response(response, data, retry_count)
          end
        end

        def handle_error_response(response, data, retry_count)
          case response.code.to_i
          when 400
            Pushr::Daemon.logger.error("[#{@name}] JSON formatting exception received.")
          when 401
            Pushr::Daemon.logger.error("[#{@name}] Authentication exception received.")
          when 500..599
            # internal error GCM server || service unavailable: exponential back-off
            handle_error_5xx_response(response, retry_count)
          else
            Pushr::Daemon.logger.error("[#{@name}] Unknown error: #{response.code} #{response.message}")
          end
        end

        # sleep if there is a Retry-After header
        def handle_error_5xx_response(response, retry_count)
          if response.header['Retry-After']
            value = response.header['Retry-After']

            if value.to_i > 0 # Retry-After: 120
              sleep value.to_i
            elsif Date.rfc2822(value) # Retry-After: Fri, 31 Dec 1999 23:59:59 GMT
              sleep Time.now.utc - Date.rfc2822(value).to_time.utc
            end
          else
            sleep 2**retry_count
          end
        end

        def open_http(host, port)
          http = Net::HTTP.new(host, port)
          http.use_ssl = true
          http
        end

        def notification_request(data)
          headers = { 'Authorization' => "key=#{@configuration.api}",
                      'Content-type' => 'application/json',
                      'Content-length' => "#{data.length}" }
          uri = URI.parse(PUSH_URL)
          post(uri, data, headers)
        end

        def post(uri, data, headers)
          reconnect_idle if idle_period_exceeded?

          retry_count = 0

          begin
            response = @connection.post(uri.path, data, headers)
            @last_use = Time.now
          rescue EOFError, Errno::ECONNRESET, Timeout::Error => e
            retry_count += 1

            Pushr::Daemon.logger.error("[#{@name}] Lost connection to #{PUSH_URL} (#{e.class.name}), reconnecting ##{retry_count}...")

            if retry_count <= 3
              reconnect
              sleep 1
              retry
            else
              raise ConnectionError, "#{@name} tried #{retry_count - 1} times to reconnect but failed (#{e.class.name})."
            end
          end

          response
        end

        def idle_period_exceeded?
          # Timeout on the http connection is 5 minutes, reconnect after 5 minutes
          @last_use + IDLE_PERIOD < Time.now
        end

        def reconnect_idle
          Pushr::Daemon.logger.info("[#{@name}] Idle period exceeded, reconnecting...")
          reconnect
        end

        def reconnect
          @connection.finish
          @last_use = Time.now
          @connection.start
        end
      end
    end
  end
end
