require 'spec_helper'
require 'pushr/daemon'
require 'pushr/daemon/logger'
require 'pushr/message_gcm'
require 'pushr/configuration_gcm'
require 'pushr/daemon/delivery_error'
require 'pushr/daemon/gcm_support/response_handler'
require 'pushr/daemon/gcm_support/connection_gcm'

describe Pushr::Daemon::GcmSupport::ConnectionGcm do

  before(:each) do
    Pushr.configure do |config|
      config.redis = ConnectionPool.new(size: 1, timeout: 1) { MockRedis.new }
    end

    logger = double('logger')
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    Pushr::Daemon.logger = logger
  end

  describe 'sends a message' do
    let(:config) do
      Pushr::ConfigurationGcm.new(app: 'app_name', connections: 2, enabled: true, api: 'apikey')
    end
    let(:message) do
      hsh = { app: 'app_name', registration_ids: ['devicetoken'], collapse_key: 'x', delay_while_idle: false,
              time_to_live: 24 * 60 * 60, data: { test: 'test' } }
      Pushr::MessageGcm.new(hsh)
    end
    let(:connection) { Pushr::Daemon::GcmSupport::ConnectionGcm.new(config, 1) }

    it 'succesful', :vcr do
      connection.connect
      connection.write(message)
      # TODO: expect(connection.write(message).code).to eql '200'
    end

    it 'fails and should Retry-After', :vcr do
      expect_any_instance_of(Pushr::Daemon::GcmSupport::ConnectionGcm).to receive(:sleep)
      connection.connect
      connection.write(message)
    end

    it 'fails and should Retry-After with date', :vcr do
      expect_any_instance_of(Pushr::Daemon::GcmSupport::ConnectionGcm).to receive(:sleep)
      connection.connect
      connection.write(message)
    end

    it 'fails and should sleep after fail', :vcr do
      expect_any_instance_of(Pushr::Daemon::GcmSupport::ConnectionGcm).to receive(:sleep)
      connection.connect
      connection.write(message)
    end

    it 'fails of a json formatting execption', :vcr do
      connection.connect
      connection.write(message)
      # TODO: assert
    end

    it 'fails of a not authenticated execption', :vcr do
      connection.connect
      connection.write(message)
      # TODO: assert
    end
  end
end
