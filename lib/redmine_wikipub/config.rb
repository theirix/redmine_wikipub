module RedmineWikipub
    
  # Patch routes for matched host
  class RoutesPatch
    class << self
      
      # Patch routing table
      def patch
        Rails.application.routes.prepend do
          constraints(lambda { |req| RedmineWikipub::RoutesPatch.host_satisfied? req }) do
            match "projects/#{Config::settings_project}", :to => 'wiki#show', :project_id => Config::settings_project, :via => :get
            #match "projects/:id", :to => 'wiki#show', :project_id => :id, :via => :get
            root :to => 'wiki#show', :project_id => Config::settings_project, :as => 'home'
          end
        end
      end
  
      # Returns whether request is performed against choosen host
      def host_satisfied? req
        desired_hostname = Config::settings_hostname
        %w{HTTP_HOST HTTP_X_FORWARDED_HOST}.any? do |header_name|
          value = req.env[header_name]
          if !value.blank? || desired_hostname.blank?
            value = 'http://' + value unless value.starts_with? 'http://'
            URI.parse(value).host =~ /^#{desired_hostname}$/
          end          
        end
      end
    end
  end
  
  # Entry point and configuration facade
  class Config
    class << self
      def settings_hostname
        Setting.plugin_redmine_wikipub['wikipub_hostname']
      end
    
      def settings_project
        Setting.plugin_redmine_wikipub['wikipub_project']
      end
    
      def bootstrap
        Helper::check_config 
        RoutesPatch::patch
      end
    end
  end
end