require 'spec_helper'

describe Travis::Hub::Handler::Configure do
  let(:subject) { Travis::Hub::Handler::Configure.new(:configure, Hashr.new(payload)) }
  let(:job)     { stub(:id => result['id'], :update_attributes => true) }

  let(:payload) do
    {
      'type'       => 'configure',
      'repository' => { 'slug' => 'travis-ci/travis-ci' },
      'build'      => { 'id' => 1, 'commit' => '313f61b', 'config_url' => 'https://raw.github.com/travis-ci/travis-ci/313f61b/.travis.yml' }
    }
  end

  let(:result) do
    {
      'id' => 1,
      'config' => { 'script' => 'rake', 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['gemfiles/rails-2.3.x', 'gemfiles/rails-3.0.x'] }
    }
  end

  before(:each) do
    ::Job.stubs(:find).with(result['id']).returns(job)
  end

  describe 'handle' do
    describe 'sucessful configure' do
      before(:each) do
        Travis::Task::Request::Configure.any_instance.expects(:run).returns(result)
      end

      it 'retrieves the config' do
        ::Job.expects(:find).with(result['id']).returns(job)
        subject.handle
      end

      it 'updates the job' do
        job.expects(:update_attributes).with(result)
        subject.handle
      end
    end

    describe 'failed configure' do
      before(:each) do
        Travis::Task::Request::Configure.any_instance.expects(:run).raises(StandardError)
      end

      it 'lets the error propagate' do
        expect { subject.handle }.to raise_error(StandardError)
      end
    end
  end

  describe 'metrics' do
    before(:each) do
      Travis::Task::Request::Configure.any_instance.stubs(:run).returns({})
    end

    it 'increments a counter when a configure message is received' do
      expect { subject.handle }.to change { Metriks.meter('travis.hub.configure.received').count }
    end

    it 'increments a counter when a configure message is completed' do
      Travis::Task::Request::Configure.stubs(:run).raises(StandardError)
      expect { subject.handle }.to change { Metriks.meter('travis.hub.configure.completed').count }
    end

    it 'increments a counter when processing a configure message raises an exception' do
      Travis::Task::Request::Configure.any_instance.stubs(:run).raises(StandardError)
      expect { subject.handle rescue nil }.to change { Metriks.meter('travis.hub.configure.failed').count }
    end
  end
end

