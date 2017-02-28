describe Build do
  let(:state)  { :created }
  let(:params) { {} }
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:build)  { FactoryGirl.create(:build, repository: repo, state: state) }
  let(:now)    { Time.now }
  before       { Travis::Event.stubs(:dispatch) }

  def receive
    build.send(:"#{event}!", params)
  end
end
