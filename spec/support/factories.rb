require 'factory_girl'

FactoryGirl.define do
  factory :repository do
    description     'the repo description'
    github_language 'ruby'
    owner_name      'travis-ci'
    name            'travis-core'
    default_branch  'master'
    url             'https://github.com/travis-ci/travis-core'
  end

  factory :request do
    association :commit
    token       'token'
    event_type  'push'
  end

  factory :pull_request
  factory :tag

  factory :commit do
    commit          '62aae5f70ceee39123ef'
    branch          'master'
    message         'the commit message'
    committed_at    '2011-11-11T11:11:11Z'
    committer_name  'Sven Fuchs'
    committer_email 'me@svenfuchs.com'
    author_name     'Sven Fuchs'
    author_email    'me@svenfuchs.com'
    compare_url     'https://github.com/travis-ci/travis-core/compare/master...develop'
  end

  factory :build do
    association :repository
    association :request
    association :commit
    config      { {} }
    number      1
    state       :created
    branch      'master'
    event_type  :push
  end

  factory :stage do
    state :created
  end

  factory :job do
    association :repository
    association :commit
    build       { FactoryGirl.build(:build) }
    config      { {} }
    number      '1.1'
    state       :created
  end

  factory :user do
  end

  factory :branch do
  end
end
