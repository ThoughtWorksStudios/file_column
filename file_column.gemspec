require 'rake/gempackagetask'

Gem::Specification.new do |gem|
  gem.name = "file_column"
  gem.version = "0.1.0"
  
  gem.authors = ["Mingle SaaS team"]
  gem.email = %q{mingle.saas@thoughtworks.com}
  
  gem.add_dependency 'rails', '2.3.8'
  gem.add_dependency 'sqlite3'
  gem.add_dependency 'rmagick'
  
  gem.homepage = %q{https://github.com/ThoughtWorksStudios/file_column}
  gem.require_paths = ["lib"]
  gem.summary = "File attachment library for ruby"
  gem.files = FileList["{lib,test}/**/*"].exclude("rdoc").to_a + ["Rakefile", "README", "CHANGELOG", "s3_env.example"]
end