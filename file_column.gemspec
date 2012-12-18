Gem::Specification.new do |gem|
  gem.name = "file_column_with_s3"
  gem.version = "0.1.1"

  gem.authors = ["Mingle SaaS team"]
  gem.email = %q{mingle.saas@thoughtworks.com}

  gem.add_dependency 'rails', '~>2.3.8'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'rmagick'
  gem.add_development_dependency 'aws-sdk', '~>1.7.1'

  gem.homepage = %q{https://github.com/ThoughtWorksStudios/file_column}
  gem.require_paths = ["lib"]
  gem.summary = "File attachment library for ruby"
  gem.files = Dir['Rakefile', '{lib,test}/**/*', 'README', 'CHANGELOG', 's3_env.example'] & `git ls-files -z`.split("\0")
end
