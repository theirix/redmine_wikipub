module RedmineWikipub
    
  # Patch routes for matched host
  class RoutesPatch
    class << self
      
      # Patch routing table
      def patch
        Rails.application.routes.prepend do
          constraints(lambda { |req| RedmineWikipub::Helper.host_satisfied? req }) do
            match "projects/#{Config::settings_project}", :to => 'wiki#show', :project_id => Config::settings_project, :via => :get
            #match "projects/:id", :to => 'wiki#show', :project_id => :id, :via => :get
            root :to => 'wiki#show', :project_id => Config::settings_project, :as => 'home'
          end
        end
      end
    end
  end
  
  # Patch MenuHelper method
  module MenuHelperPatch 
    def self.included(base)
      
      base.class_eval do
        alias_method :original_allowed_node?, :allowed_node?

        # Patched method to check whether a menu node is applicable
        def allowed_node?(node, user, project)  
          if request && RedmineWikipub::Helper.host_satisfied?(request)
            if project && project.name == RedmineWikipub::Config::settings_project
              if node && [:activity, :overview].include?(node.name)
                #Rails.logger.debug("Ban view for the wiki project") if Rails.logger && Rails.logger.debug?      
                return false
              end
            end
          end  
          original_allowed_node? node, user, project                              
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
        return if Config::settings_project.blank?
        
        RoutesPatch::patch
        ActionDispatch::Callbacks.to_prepare do
          Redmine::MenuManager::MenuHelper.send(:include, MenuHelperPatch)
        end
        # ProjectPatch::patch
      end
    end
  end
end