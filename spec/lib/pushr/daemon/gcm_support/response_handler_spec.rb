require 'spec_helper'
require 'pushr/daemon'
require 'pushr/gcm'
require 'pushr/feedback_gcm'
require 'pushr/message_gcm'

describe Pushr::Daemon::GcmSupport::ResponseHandler do
  it 'should handle no errors' do
    json = '{"multicast_id":7726000338213371155,"success":1,"failure":0,"canonical_ids":0,' \
           '"results":[{"message_id":"0:1397767098298993%00525e0300000078"}]}'
    response = double('response')
    allow(response).to receive(:body).and_return(json)

    message = double('message')
    allow(message).to receive('registration_ids').and_return(['device_id'])
    handler = Pushr::Daemon::GcmSupport::ResponseHandler.new(response, message)
    handler.handle
    # TODO: assert
  end

  it 'should handle Unavailable' do
    json = '{"multicast_id":7726000338213371155,"success":0,"failure":1,"canonical_ids":0,' \
           '"results":[{"error":"Unavailable"}]}'
    response = double('response')
    allow(response).to receive(:body).and_return(json)

    message = double('message')
    allow(message).to receive('registration_ids').and_return(['device_id'])
    expect(message).to receive('registration_ids=').with(['device_id'])
    allow(message).to receive('save')
    handler = Pushr::Daemon::GcmSupport::ResponseHandler.new(response, message)
    handler.handle
    # TODO: assert
  end
  it 'should work' do
    t = double('test')
    allow(t).to receive(:foobar).and_return(1)
    expect(t.clone.foobar).to eq(1)
  end

  it 'should handle InvalidRegistration' do
    expect_any_instance_of(Pushr::FeedbackGcm).to receive(:save)
    json = '{"multicast_id":7726000338213371155,"success":0,"failure":1,"canonical_ids":0,' \
           '"results":[{"error":"InvalidRegistration"}]}'
    response = double('response')
    allow(response).to receive(:body).and_return(json)

    message = double('message')
    allow(message).to receive('registration_ids').and_return(['device_id'])
    allow(message).to receive(:app).and_return('app_name')
    handler = Pushr::Daemon::GcmSupport::ResponseHandler.new(response, message)
    handler.handle
  end

  it 'should handle registration_id' do
    expect_any_instance_of(Pushr::FeedbackGcm).to receive(:save)
    json = '{"multicast_id":7726000338213371155,"success":1,"failure":0,"canonical_ids":1,' \
           '"results":[{"message_id":"message_id","registration_id":"new_reg_id"}]}'
    response = double('response')
    allow(response).to receive(:body).and_return(json)

    message = double('message')
    allow(message).to receive('registration_ids').and_return(['device_id'])
    allow(message).to receive(:app).and_return('app_name')
    handler = Pushr::Daemon::GcmSupport::ResponseHandler.new(response, message)
    handler.handle
  end

  it 'should handle NotRegistered' do
    expect_any_instance_of(Pushr::FeedbackGcm).to receive(:save)
    json = '{"multicast_id":7726000338213371155,"success":0,"failure":1,"canonical_ids":0,' \
           '"results":[{"error":"NotRegistered"}]}'
    response = double('response')
    allow(response).to receive(:body).and_return(json)

    message = double('message')
    allow(message).to receive('registration_ids').and_return(['device_id'])
    allow(message).to receive(:app).and_return('app_name')
    handler = Pushr::Daemon::GcmSupport::ResponseHandler.new(response, message)
    handler.handle
  end
end
