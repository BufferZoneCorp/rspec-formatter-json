Gem::Specification.new do |s|
  s.name        = 'knot-rspec-formatter-json'
  s.version     = '3.13.1'
  s.summary     = 'JSON formatter for RSpec test output'
  s.description = 'Formats RSpec output as JSON for CI/CD pipelines, test reporting dashboards, and tooling integrations.'
  s.authors     = ['rspec-community']
  s.email       = ['maintainer@knot-theory.dev']
  s.homepage    = 'https://github.com/BufferZoneCorp/rspec-formatter-json'
  s.license     = 'MIT'
  s.files       = Dir['lib/**/*.rb']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7.0'
  s.metadata    = {
    "source_code_uri" => "https://github.com/BufferZoneCorp/rspec-formatter-json",
    "changelog_uri"   => "https://github.com/BufferZoneCorp/rspec-formatter-json/blob/main/CHANGELOG.md"
  }
end
