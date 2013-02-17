Redmine::Plugin.register :redmine_wikipub do
  name 'Redmine Wikipub plugin'
  author 'Eugene Seliverstov'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  settings :default => {'wikipub_hostname' => "", 'wikipub_project' => ""},
    :partial => 'settings/wikipub_settings'
  
end

require 'redmine_wikipub'
RedmineWikipub::Config.bootstrap