$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "redmine_wikipub/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "redmine_wikipub"
  s.version     = RedmineWikipub::VERSION
  s.authors     = ["Eugene Seliverstov"]
  s.email       = ["theirix@gmail.com"]
  s.homepage    = "https://github.com/theirix/redmine_wikipub"
  s.summary     = "Redmine Wikipub plugin"
  s.description = "Redmine plugin. Publish project as a public wiki"

  s.files = Dir["{app,config,lib,rails}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "actionmailer-with-request", ">=0.3.0"
end
