require 'redmine/menu_manager'
require 'redmine/themes'
require 'application_helper'

module RedmineWikipub

  # Patch routes for matched host
  class WikipubRoutes
    class << self

      # Patch routing table
      def prepend
        Rails.application.routes.prepend do
          constraints(lambda { |req| RedmineWikipub::Helper.host_satisfied? req }) do
            match "projects/#{Config::settings_project}", :to => 'wiki#show', :project_id => Config::settings_project, :via => :get
            match "projects", :to => redirect('/')
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
            if !project || project.name == RedmineWikipub::Config::settings_project
              if node && RedmineWikipub::Helper.excluded_menu_names.include?(node.name)
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

  # Theme patch
  # Allows to use a custom theme for wikipub project
  module ThemesPatch
    def self.included(base)
      base.class_eval do

        # patched method
        def current_theme
          if request && RedmineWikipub::Helper.host_satisfied?(request)
            theme_id = (RedmineWikipub::Config::settings_theme || Setting.ui_theme)
          else
            theme_id = String.new(Setting.ui_theme)
          end
          Rails.logger.debug("Check theme #{theme_id}") if Rails.logger && Rails.logger.debug?
          @current_theme = Redmine::Themes.theme(theme_id)
        end

      end
    end
  end

  # Patch ApplicationController to provide a view helper
  module ViewHelperPatch
    def self.included(base)
      base.class_eval do

        def options_redmine_themes
          items = Redmine::Themes.themes.collect {|t| [t.name, t.id] } + [[I18n.t(:label_default), '']]
          options_for_select items, (RedmineWikipub::Config::settings_theme || '')
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

      def settings_theme
        Setting.plugin_redmine_wikipub['wikipub_theme']
      end

      def bootstrap
        check_config
        return if Config::settings_project.blank?

        WikipubRoutes::prepend

        # Rails classes patches
        ActionDispatch::Callbacks.to_prepare do
          unless Redmine::MenuManager::MenuHelper.included_modules.include? MenuHelperPatch
            Redmine::MenuManager::MenuHelper.send(:include, MenuHelperPatch)
          end
          unless ApplicationHelper.included_modules.include? ThemesPatch
            ApplicationHelper.send(:include, ThemesPatch)
          end
          unless ApplicationHelper.included_modules.include? ViewHelperPatch
            ApplicationHelper.send(:include, ViewHelperPatch)
          end
        end
      end

      private

      def check_config
        %w{hostname project theme}.each do |shortkey|
          Setting.plugin_redmine_wikipub['wikipub_'+shortkey] ||= ''
        end

        Rails.logger.debug("Wikipub settings: host=#{Config::settings_hostname} project=#{Config::settings_project}") if Rails.logger && Rails.logger.debug?
      end


    end
  end
end
