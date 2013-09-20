require 'application_helper'
require 'json'

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
		end

    class << self

			def entries
				@@entries
			end

      # Entry point
      # Check config, set up routes and hooks
      def bootstrap
        load_config

        Patches::RoutesPatch::prepend

        # Rails classes patches
        ActionDispatch::Callbacks.to_prepare do
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

      private

      def load_config
        json_config = JSON::load Setting.plugin_redmine_wikipub['wikipub_extraconf'] ||= "{'entries':[]}"
				@@entries = json_config['entries'].map { |je| Entry.new je }

				@@entries.each do |e|
					Rails.logger.debug("Wikipub entry: hostregex=#{e.hostname} "+
						"project=#{e.project} theme=#{e.theme} allowaccount=#{e.allowaccount?}") if Rails.logger && Rails.logger.debug?
				end
      end


    end
  end
end
