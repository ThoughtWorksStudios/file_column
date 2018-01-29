Gem::Specification.new do |gem|
  gem.name = "file_column_with_s3"
  gem.version = "0.2.0"

  gem.authors = ["Mingle SaaS team"]
  gem.email = %q{mingle.saas@thoughtworks.com}

  gem.add_dependency 'mingle-storage'
  gem.add_development_dependency 'jdbc-sqlite3'
  gem.add_development_dependency 'mini_magick'
  gem.add_development_dependency 'aws-sdk-s3'
  gem.add_development_dependency "nokogiri"
  gem.homepage = %q{https://github.com/ThoughtWorksStudios/file_column}
  gem.require_paths = ["lib"]
  gem.summary = "File attachment library for ruby"
  gem.files = Dir['Rakefile', '{lib,test}/**/*', 'README', 'CHANGELOG', 's3_env.example'] & `git ls-files -z`.split("\0")
end
