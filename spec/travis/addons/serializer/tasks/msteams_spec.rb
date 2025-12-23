describe Travis::Addons::Serializer::Tasks::Msteams do
  let(:owner)  { FactoryBot.create(:user, login: 'devtactics') }
  let(:repo)   { FactoryBot.create(:repository, owner_name: 'devtactics', name: 'test-repo') }
  let(:build)  { FactoryBot.create(:build, owner:, repository: repo, state:, pull_request: pull, tag:) }
  let(:commit) { build.commit }
  let(:pull)   { nil }
  let(:tag)    { nil }
  let(:state)  { :passed }
  let(:data)   { described_class.new(build).data }

  describe 'webhook format' do
    it 'generates valid MS Teams adaptive card structure' do
      expect(data[:type]).to eq('message')
      expect(data[:attachments]).to be_an(Array)
      expect(data[:attachments].size).to eq(1)

      attachment = data[:attachments][0]
      expect(attachment[:contentType]).to eq('application/vnd.microsoft.card.adaptive')

      content = attachment[:content]
      expect(content[:type]).to eq('AdaptiveCard')
      expect(content[:version]).to eq('1.5')
      expect(content[:body]).to be_an(Array)
    end

    it 'includes action buttons' do
      actions = data[:attachments][0][:content][:body].find { |item| item[:type] == 'ActionSet' }
      expect(actions[:actions].size).to be >= 1

      view_build = actions[:actions].find { |action| action[:title] == 'View Build' }
      expect(view_build[:url]).to include(repo.slug)
    end
  end

  describe 'build state badges' do
    let(:badge) { data[:attachments][0][:content][:body][0][:columns][0][:items][0] }

    context 'when build passed' do
      let(:state) { :passed }

      it 'shows passed badge' do
        expect(badge[:text]).to eq('Passed')
        expect(badge[:style]).to eq('Good')
        expect(badge[:icon]).to eq('CheckmarkCircle')
      end
    end

    context 'when build failed' do
      let(:state) { :errored }

      it 'shows failed badge' do
        expect(badge[:text]).to eq('Failed')
        expect(badge[:style]).to eq('Attention')
        expect(badge[:icon]).to eq('ErrorCircle')
      end
    end
  end

  describe 'build information' do
    let(:desktop_header) { data[:attachments][0][:content][:body][0] }
    let(:metadata) { data[:attachments][0][:content][:body].find { |item| item[:type] == 'ColumnSet' && item[:targetWidth] == 'AtLeast:Narrow' && item[:spacing] == 'ExtraLarge' } }

    it 'displays repository and commit details' do
      expect(desktop_header[:columns][1][:items][0][:text]).to eq('devtactics/test-repo')
      expect(metadata[:columns][0][:items][1][:columns][1][:items][0][:text]).to eq(commit.commit[0..6])
      expect(metadata[:columns][1][:items][1][:columns][1][:items][0][:text]).to eq(commit.branch)
      expect(metadata[:columns][2][:items][1][:columns][1][:items][0][:text]).to eq(commit.author_name)
    end
  end

  describe 'pull request info' do
    context 'when build is for a pull request' do
      let(:pull) { FactoryBot.create(:pull_request, number: 123, title: 'Test PR') }

      before do
        build.update(event_type: 'pull_request', pull_request_number: 123)
      end

      it 'includes pull request section' do
        pr_section = data[:attachments][0][:content][:body].find do |item|
          item.is_a?(Hash) &&
            item[:type] == 'ColumnSet' &&
            item.dig(:columns, 0, :items, 0, :text)&.include?('Pull request')
        end
        expect(pr_section).to be_present
        expect(pr_section[:columns][0][:items][0][:text]).to eq('Pull request #123')
      end
    end

    context 'when build is not for a pull request' do
      let(:pull) { nil }

      it 'does not include pull request section' do
        pr_sections = data[:attachments][0][:content][:body].select do |item|
          item.is_a?(Hash) &&
            item.dig(:columns, 0, :items, 0, :text)&.include?('Pull request')
        end
        expect(pr_sections).to be_empty
      end
    end
  end
end
