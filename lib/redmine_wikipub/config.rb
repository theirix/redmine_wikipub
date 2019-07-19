require 'json'
require 'cgi'

module RedmineWikipub

  # Entry point and configuration facade
  class Config

    class Entry
      def initialize json_piece
        @json = json_piece
      end

      def hostname
        @json['hostname']
      end

      def project
        @json['project']
      end

      def theme
        @json['theme']
      end

      def allowaccount?
        @json['allowaccount']
      end

      def analytics
        @json['analytics']
      end
    end

    class << self

      def entries
        @@entries
      end

      def default_analytics
        @@default_analytics
      end

      # Entry point
      # Check config, set up routes and hooks
      def bootstrap

        # Rails classes patches
        if Rails::VERSION::MAJOR >= 5 and Rails::VERSION::MINOR >= 1
            reloader = ActiveSupport::Reloader
        else
            reloader = ActionDispatch::Callbacks
        end
        reloader.to_prepare do

          RedmineWikipub::Config::load_config

          Patches::RoutesPatch::prepend

          unless Redmine::MenuManager::MenuHelper.included_modules.include? RedmineWikipub::Patches::MenuHelperPatch
            Redmine::MenuManager::MenuHelper.send(:include, Patches::MenuHelperPatch)
          end
          unless ApplicationHelper.included_modules.include? RedmineWikipub::Patches::ThemesPatch
            ApplicationHelper.send(:include, Patches::ThemesPatch)
          end
          unless Mailer.included_modules.include? RedmineWikipub::Patches::MailerPatch
            Mailer.send(:include, Patches::MailerPatch)
          end
          unless AccountController.included_modules.include? RedmineWikipub::Patches::AccountControllerPatch
            AccountController.send(:include, Patches::AccountControllerPatch)
          end
        end
      end

      def load_config
        json_config = nil
        begin
          if Setting.plugin_redmine_wikipub && !Setting.plugin_redmine_wikipub['wikipub_extraconf'].blank?
            json_config = JSON::load(Setting.plugin_redmine_wikipub['wikipub_extraconf'])
          end
        rescue => exc
          Rails.logger.warn("JSON load failed: #{exc}") if Rails.logger && Rails.logger.warn?
        end
        json_config = JSON::load('{"entries":[]}') unless json_config

        @@entries = json_config['entries'].map { |je| Entry.new je }
        @@entries.each do |e|
          Rails.logger.debug("Wikipub entry: hostregex=#{e.hostname} "+
          "project=#{e.project} theme=#{e.theme} " +
          "allowaccount=#{e.allowaccount?} " +
          "analytics=#{e.analytics}") if Rails.logger && Rails.logger.debug?
        end
        @@default_analytics = json_config['default_analytics']
      end


    end # << self
  end
end
