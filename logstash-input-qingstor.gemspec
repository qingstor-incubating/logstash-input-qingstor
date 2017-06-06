Gem::Specification.new do |s|
  s.name          = 'logstash-input-qingstor'
  s.version       = '0.1.5'
  s.licenses      = ['Apache License (2.0)']
  s.summary       = 'logstash input plugin for QingStor'
  s.description   = 'Fetch file from Qingstor as the input of logstash'
  s.homepage      = 'https://github.com/yunify/logstash-input-qingstor'
  s.authors       = ['Evan Zhao']
  s.email         = 'tacingiht@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*', 'spec/**/*', 'vendor/**/*', '*.gemspec', '*.md',
                'CONTRIBUTORS', 'Gemfile', 'LICENSE', 'NOTICE.TXT']

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'input' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '>=1.6', '<=2.99'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'stud', '>= 0.0.22'
  s.add_runtime_dependency 'qingstor-sdk', '>=1.9.2'

  s.add_development_dependency 'logstash-devutils'
end
