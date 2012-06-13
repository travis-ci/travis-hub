require 'spec_helper'
require 'json'

describe Travis::Hub::Instrument::Handler::Job do
  include Travis::Testing::Stubs

  let(:payload)   { { :id => 1, :some => :payload } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:handler)   { Travis::Hub::Handler::Job.new(nil, Hashr.new(payload)) }
  let(:job)       { stub('job', :update_attributes => nil) }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    Job.stubs(:find).returns(job)
    Job::Test.stubs(:append_log!)
  end

  it 'publishes a payload on update' do
    handler.event = :'job:test:started'
    handler.handle

    publisher.events.last.should == {
      :msg => 'Travis::Hub::Handler::Job#update for #<Job id="1">',
      :event => :'job:test:started',
      :payload => payload,
      :result => nil,
      :uuid => Travis.uuid
    }
  end

  it 'publishes a payload on log' do
    handler.event = :'job:test:log'
    handler.handle

    publisher.events.first.should == {
      :msg => 'Travis::Hub::Handler::Job#log for #<Job id="1">',
      :event => :'job:test:log',
      :payload => payload,
      :result => nil,
      :uuid => Travis.uuid
    }
  end
end
