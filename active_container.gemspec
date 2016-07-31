Gem::Specification.new do |spec|
  spec.name          = 'active_container'
  spec.version       = '0.0.1'
  spec.authors       = ['Travis Herrick']
  spec.email         = ['tthetoad@gmail.com']
  spec.summary       = 'Container for ActiveModel/Record type things'
  spec.description   = '
    Trim the fatty models. Use ActiveContainer.
  '.strip
  spec.homepage      = 'http://www.bitbucket.org/ToadJamb/active_container'
  spec.license       = 'LGPL-3.0'

  spec.files         = Dir['lib/**/*.rb', 'license/*']

  spec.extra_rdoc_files << 'readme.md'

  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake_tasks'
  spec.add_development_dependency 'gems'
  spec.add_development_dependency 'cane'
  spec.add_development_dependency 'rspec'
end
