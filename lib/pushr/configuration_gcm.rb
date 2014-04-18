module Pushr
  class ConfigurationGcm < Pushr::Configuration
    attr_accessor :id, :type, :app, :enabled, :connections, :api
    validates :api, presence: true

    def name
      :gcm
    end

    def to_json
      MultiJson.dump(type: self.class.to_s, app: app, enabled: enabled, connections: connections, api: api)
    end
  end
end
