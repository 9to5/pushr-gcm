module Pushr
  class ConfigurationGcm < Pushr::Configuration
    attr_accessor :gem, :type, :app, :enabled, :connections, :key
    validates :key, :presence => true

    def name
      :gcm
    end

    def to_json
      ::MultiJson.dump({gem: 'push-gcm', type: self.class.to_s, app: @app, enabled: @enabled, connections: @connections, key: @key})
    end
  end
end