[true, false].each do |logs_api_enabled|
  describe Log, logs_api_enabled: logs_api_enabled do
    let(:logs_api) { mock('logs_api') }
    subject { FactoryGirl.create(:log) }

    before do
      Travis::Hub::Support::Logs.stubs(:new).returns(logs_api)
    end

    it 'can be cleared' do
      logs_api.expects(:update) if logs_api_enabled

      subject.clear
      expect(subject.content.to_s).to be_empty
      expect(subject.aggregated_at).to be_nil
      expect(subject.archived_at).to be_nil
      expect(subject.archive_verified).to be_nil
      expect(subject.removed_at).to be_nil
      expect(subject.removed_by).to be_nil

      unless logs_api_enabled
        expect(Log::Part.where(log_id: subject.id).count)
          .to eq(0)
      end
    end

    it 'can be canceled' do
      logs_api.expects(:append_log_part) if logs_api_enabled

      subject.canceled(
        event: :push,
        number: 4,
        branch: 'foop',
        pull_request_number: 11
      )

      unless logs_api_enabled
        expect(Log::Part.where(log_id: subject.id).count)
          .to be > 0
      end
    end
  end
end
