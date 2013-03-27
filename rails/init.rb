require "redmine_wikipub/version"

Redmine::Plugin.register :redmine_wikipub do
  name 'Redmine Wikipub plugin'
  author 'Eugene Seliverstov'
  description 'Publish project as a public wiki'
  version RedmineWikipub::VERSION
  url 'http://github.com/theirix/redmine_wikipub'
  
  settings :default => {'wikipub_hostname' => "", 'wikipub_project' => "", 
      'wikipub_theme' => "", 'wikipub_allowaccount' => false},
    :partial => 'settings/wikipub_settings'
  
end

require 'redmine_wikipub'
RedmineWikipub::Config.bootstrap