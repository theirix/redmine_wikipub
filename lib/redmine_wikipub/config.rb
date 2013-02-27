require 'application_helper'

module RedmineWikipub

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

      # Entry point
      # Check config, set up routes and hooks
      def bootstrap
        check_config

        Patches::RoutesPatch::prepend

        # Rails classes patches
        ActionDispatch::Callbacks.to_prepare do
          unless Redmine::MenuManager::MenuHelper.included_modules.include? RedmineWikipub::Patches::MenuHelperPatch
            Redmine::MenuManager::MenuHelper.send(:include, Patches::MenuHelperPatch)
          end
          unless ApplicationHelper.included_modules.include? RedmineWikipub::Patches::ThemesPatch
            ApplicationHelper.send(:include, Patches::ThemesPatch)
          end
          unless ApplicationHelper.included_modules.include? RedmineWikipub::Patches::ViewHelperPatch
            ApplicationHelper.send(:include, Patches::ViewHelperPatch)
          end
        end
      end

      private

      def check_config
        %w{hostname project theme}.each do |shortkey|
          Setting.plugin_redmine_wikipub['wikipub_'+shortkey] ||= ''
        end

        Rails.logger.debug("Wikipub settings: hostregex=#{Config::settings_hostname} project=#{Config::settings_project}") if Rails.logger && Rails.logger.debug?
      end


    end
  end
end
