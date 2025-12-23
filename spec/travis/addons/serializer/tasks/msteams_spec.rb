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
    let(:header) { data[:attachments][0][:content][:body].find { |item| item[:type] == 'ColumnSet' && item[:columns]&.any? { |col| col[:items]&.any? { |i| i[:text]&.include?('**') } } } }
    let(:metadata) { data[:attachments][0][:content][:body].find { |item| item[:type] == 'ColumnSet' && item[:columns]&.all? { |col| col[:width] == 'auto' } } }

    it 'displays repository and commit details' do
      expect(header[:columns][1][:items][0][:text]).to eq("**#{repo.slug}**")

      columns = metadata[:columns]

      commit_column = columns.find { |col| col[:items].any? { |item| item[:text] == 'Commit' } }
      expect(commit_column[:items][1][:text]).to eq(commit.commit[0..6])

      branch_column = columns.find { |col| col[:items].any? { |item| item[:text] == 'Branch' } }
      expect(branch_column[:items][1][:text]).to eq(commit.branch)

      author_column = columns.find { |col| col[:items].any? { |item| item[:text] == 'Author' } }
      expect(author_column[:items][1][:text]).to eq(commit.author_name)
    end

    context 'when build errored' do
      let(:state) { :errored }

      it 'shows Errored emoji' do
        emoji_block = data[:attachments][0][:content][:body].find { |item| item[:type] == 'ColumnSet' && item[:columns]&.any? { |col| col[:items]&.any? { |i| i[:text] == '⚠️' } } }
        expect(emoji_block[:columns][0][:items][0][:text]).to eq('⚠️')
      end
    end

    context 'when build is a pull request' do
      let(:pull) { FactoryBot.create(:pull_request, number: 123) }

      it 'shows pull request information' do
        body = data[:attachments][0][:content][:body]
        pr_block = body.find { |item| item[:type] == 'TextBlock' && item[:text]&.include?('Pull request') }

        expect(pr_block).not_to be_nil, 'PR block not found in body'
        expect(pr_block[:text]).to eq('**Pull request #123**')
      end
    end

    context 'when build is not a pull request' do
      let(:pull) { nil }

      it 'does not show pull request section' do
        pr_block = data[:attachments][0][:content][:body].find { |item| item[:type] == 'TextBlock' && item[:text]&.include?('Pull request') }
        expect(pr_block).to be_nil
      end
    end
  end
end
