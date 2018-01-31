Gem::Specification.new do |gem|
  gem.name = "file_column_with_s3"
  gem.version = "0.3.0"

  gem.authors = ["Mingle SaaS team"]
  gem.email = %q{mingle.saas@thoughtworks.com}

  gem.add_dependency 'mingle-storage', '~> 0.1'
  gem.add_dependency 'activesupport', '~> 5.0'
  gem.add_dependency 'actionview', '~> 5.0'
  gem.add_dependency 'actionpack', '~> 5.0'
  gem.license     = "MIT"

  gem.add_development_dependency 'jdbc-sqlite3', '~> 0'
  gem.homepage = %q{https://github.com/ThoughtWorksStudios/file_column}
  gem.require_paths = ["lib"]
  gem.summary = "File attachment library for ruby"
  gem.files = Dir['Rakefile', '{lib,test}/**/*', 'README', 'CHANGELOG', 's3_env.example'] & `git ls-files -z`.split("\0")
end
