Gem::Specification.new do |s|
  s.name        = 'travis-hub'
  s.version     = '0.0.1'
  s.summary     = 'It is the hub of the Travis!'
  s.description = s.summary + '  With flair!'
  s.authors     = ['Travis CI GmbH']
  s.email       = ['contact+travis-hub@travis-ci.org']
  s.homepage    = 'https://github.com/travis-ci/travis-hub'
  s.license     = 'MIT'

  # travis-hub is not intended to be gem installable :smiley_cat:
  s.metadata['allowed_push_host'] = 'https://not-rubygems.example.com'

  s.files         = `git ls-files -z`.split("\x0")
  s.require_paths = %w(lib)
end
