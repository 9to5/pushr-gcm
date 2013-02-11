module Pushr
  module Daemon
    module GcmSupport
      class ConnectionError < StandardError; end

      class ConnectionGcm
        attr_reader :response, :name, :configuration
        PUSH_URL = "https://android.googleapis.com/gcm/send"
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
          @response = notification_request(data)

          # if @response.code.eql? "200"
          #   puts "success, but can have an exception in "
          # elsif @response.code.eql? "400"
          #   puts "formatting exception"
          # elsif @response.code.eql? "401"
          #   puts "authentication exception"
          # elsif @response.code.eql? "500"
          #   puts "internal error GCM server"
          # elsif response.code.eql? "503"
          #   puts "service un-available: exponential back-off"
          #
          #   # do not retry for now
          #
          #   # @response.header.each_header do |key, value|
          #   #   if key.capitalize == "Retry-After".capitalize
          #   #     # TODO USE DELAY
          #   #     @delay_by = value
          #   #   end
          #   # end
          #   # TODO or exponentional back-off
          # end
        end

        def check_for_error(notification)
          if @response.code.eql? "200"
            hsh = MultiJson.load(@response.body)
            if hsh["failure"] == 1
              msg = hsh["results"][0]["error"]

              # MissingRegistration, handled by validation
              # MismatchSenderId, configuration error by client
              # MessageTooBig, TODO: add validation

              if msg == "NotRegistered" or msg == "InvalidRegistration"
                Pushr::FeedbackGcm.new(app: @configuration.name, failed_at: Time.now, device: notification.device, follow_up: 'delete').save
              end

              Pushr::Daemon.logger.error("[#{@name}] Error received.")
              raise Pushr::DeliveryError.new(@response.code, nil, msg, "GCM", false)
            elsif hsh["canonical_ids"] == 1
              # success, but update device token
              update_to = hsh["results"][0]["registration_id"]
              Pushr::FeedbackGcm.new(app: @configuration.name, failed_at: Time.now, device: notification.device, follow_up: 'update', update_to: update_to).save
            end
          else
            Pushr::Daemon.logger.error("[#{@name}] Error received.")
            raise Pushr::DeliveryError.new(@response.code, nil, @response.message, "GCM", false)
          end
        end

        private

        def open_http(host, port)
          http = Net::HTTP.new(host, port)
          http.use_ssl = true
          return http
        end

        def notification_request(data)
          headers = { "Authorization" => "key=#{@configuration.key}",
                     "Content-type" => "application/json",
                     "Content-length" => "#{data.length}" }
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
              raise ConnectionError, "#{@name} tried #{retry_count-1} times to reconnect but failed (#{e.class.name})."
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