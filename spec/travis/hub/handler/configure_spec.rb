require 'spec_helper'

describe Travis::Hub::Handler::Configure do
  let(:subject) { Travis::Hub::Handler::Configure.new(:configure, Hashr.new(payload)) }
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
      'config' => {
        'script' => 'rake',
        'rvm' => ['1.8.7', '1.9.2'],
        'gemfile' => ['gemfiles/rails-2.3.x', 'gemfiles/rails-3.0.x']
      }
    }
  end

  describe '#handle' do
    describe 'sucessful configure' do
      before(:each) do
        ::Travis::Tasks::ConfigureBuild.any_instance.expects(:run).returns(result)
        job = mock()
        job.expects(:update_attributes).returns(true)
        ::Job.expects(:find).with(result['id']).returns(job)
      end

      it "retrieves the config and updates the job" do
        subject.handle
      end
    end

    describe 'failed configure' do
      before(:each) do
        ::Travis::Tasks::ConfigureBuild.any_instance.expects(:run).raises(StandardError)
      end

      it "lets the error proporgate" do
        expect {
          subject.handle
        }.to raise_error(StandardError)
      end
    end
  end

  describe 'metrics' do
    before(:each) do
      ::Travis::Tasks::ConfigureBuild.any_instance.stubs(:run).returns({})
      job = mock()
      job.stubs(:update_attributes).returns(true)
      ::Job.stubs(:find).returns(job)
    end

    it "increments a counter when a configure message is received" do
      expect {
        subject.handle
      }.to change {
        Metriks.meter('travis.hub.configure.received').count
      }
    end

    it "increments a counter when a configure message is completed" do
      ::Travis::Tasks::ConfigureBuild.stubs(:run).raises(StandardError)
      expect {
        subject.handle
      }.to change {
        Metriks.meter('travis.hub.configure.completed').count
      }
    end

    it "increments a counter when processing a configure message raises an exception" do
      ::Travis::Tasks::ConfigureBuild.any_instance.stubs(:run).raises(StandardError)
      expect {
        subject.handle rescue nil
      }.to change {
        Metriks.meter('travis.hub.configure.failed').count
      }
    end
  end
end

