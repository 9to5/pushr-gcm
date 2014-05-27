require 'spec_helper'
require 'pushr/daemon/gcm'
require 'pushr/daemon/gcm_support/connection_gcm'

describe Pushr::Daemon::Gcm do
  let(:gcm) { Pushr::Daemon::Gcm.new(test: 'test') }

  describe 'responds to' do
    it 'configuration' do
      expect(gcm.configuration).to eql(test: 'test')
    end
  end
end
