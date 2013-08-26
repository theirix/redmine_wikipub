Redmine::Plugin.register :redmine_wikipub do
  name 'Redmine Wikipub plugin'
  author 'Eugene Seliverstov'
  description 'Publish project as a public wiki'
  version '0.0.7'
  url 'http://github.com/theirix/redmine_wikipub'
  
  settings :default => {'wikipub_hostname' => "", 'wikipub_project' => "", 
      'wikipub_theme' => "", 'wikipub_allowaccount' => false},
    :partial => 'settings/wikipub_settings'
  
end

require 'redmine_wikipub'
RedmineWikipub::Config.bootstrap
