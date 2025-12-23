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
      expect(content[:version]).to eq('1.2')
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
    let(:header) { data[:attachments][0][:content][:body][0] }
    let(:emoji) { header[:columns][0][:items][0] }

    context 'when build passed' do
      let(:state) { :passed }

      it 'shows passed emoji' do
        expect(emoji[:text]).to eq('✅')
      end
    end

    context 'when build failed' do
      let(:state) { :errored }

      it 'shows failed emoji' do
        expect(emoji[:text]).to eq('⚠️')
      end
    end
  end

  describe 'build information' do
    let(:header) { data[:attachments][0][:content][:body][0] }
    let(:metadata) { data[:attachments][0][:content][:body].find { |item| item[:type] == 'FactSet' } }

    it 'displays repository and commit details' do
      expect(header[:columns][1][:items][0][:text]).to eq("**#{repo.slug}**")

      facts = metadata[:facts]
      commit_fact = facts.find { |f| f[:title] == 'Commit' }
      expect(commit_fact[:value]).to eq(commit.commit[0..6])

      branch_fact = facts.find { |f| f[:title] == 'Branch' }
      expect(branch_fact[:value]).to eq(commit.branch)

      author_fact = facts.find { |f| f[:title] == 'Author' }
      expect(author_fact[:value]).to eq(commit.author_name)
    end

    context 'when build errored' do
      let(:state) { :errored }

      it 'shows Errored status text' do
        facts = metadata[:facts]
        status_fact = facts.find { |f| f[:title] == 'Status' }
        expect(status_fact[:value]).to eq('Errored')
      end
    end
  end
end
