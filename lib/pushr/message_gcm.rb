module Pushr
  class MessageGcm < Pushr::Message
    POSTFIX = 'gcm'
    # TODO: validates max size -> The message size limit is 4096 bytes.
    # The total size of the payload data that is included in a message can't exceed 4096 bytes.
    # Note that this includes both the size of the keys as well as the values.
    attr_accessor :type, :app, :device, :collapse_key, :delay_when_idle, :time_to_live, :payload

    def to_message
      hsh = Hash.new
      hsh['registration_ids'] = [device]
      hsh['collapse_key'] = collapse_key if collapse_key
      hsh['delay_when_idle'] = delay_when_idle if delay_when_idle
      hsh['time_to_live'] = time_to_live if time_to_live
      hsh['data'] = payload
      MultiJson.dump(hsh)
    end

    def to_json
      MultiJson.dump({ type: self.class.to_s, app: @app, device: @device, collapse_key: @collapse_key, delay_when_idle: @delay_when_idle, time_to_live: @time_to_live, payload: @payload })
    end
  end
end