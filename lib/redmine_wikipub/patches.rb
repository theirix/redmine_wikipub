require 'redmine/menu_manager'
require 'redmine/themes'
require 'application_helper'
require 'mailer'
require 'auth_source'
require 'account_controller'

module RedmineWikipub
  module Patches

    # Patch routes for matched host
    class RoutesPatch
      class << self

        # Patch routing table
        def prepend
          Rails.application.routes.prepend do
            constraints(lambda { |req| RedmineWikipub::Helper.host_satisfied? req }) do
              match "projects/#{Config::settings_project}" => redirect("/projects/#{Config::settings_project}/wiki")
              match "projects/#{Config::settings_project}/activity" => redirect("/projects/#{Config::settings_project}/wiki")
              match "projects", :to => redirect('/')
              match "/", :to => redirect("/projects/#{Config::settings_project}/wiki")
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
            if request && Helper.host_satisfied?(request)
              if !project || project.name == Config::settings_project
                if node && Helper.excluded_menu_names(Config::settings_allowaccount?).include?(node.name)
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
            if request && Helper.host_satisfied?(request)
              theme_id = (Config::settings_theme || Setting.ui_theme)
            else
              theme_id = String.new(Setting.ui_theme)
            end
            #Rails.logger.debug("Check theme #{theme_id}") if Rails.logger && Rails.logger.debug?
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
            options_for_select items, (Config::settings_theme || '')
          end

          def options_redmine_projects
            items = Project.all.collect {|t| [t.name, t.identifier] }
            options_for_select items, (Config::settings_project || '')
          end

        end
      end
    end

    # Patch to provide a link to wikipub host in the registration e-mail
    module MailerPatch
      def self.included(base)
        base.class_eval do

          alias_method :original_url_for, :url_for

          def url_for(options = {})
            wikipub_host = Helper.current_wikipub_host(request)
            if wikipub_host.blank?
              original_url_for(options)
            else
              original_url_for(options.merge({:host => wikipub_host}))
            end
          end
        end
      end

    end

    # Patch to redirect user to wiki page when he activated account by registration e-mail
    module AccountControllerPatch
      def self.included(base)
        base.class_eval do
          alias_method :original_successful_authentication, :successful_authentication

          def successful_authentication(user)
            wikipub_host = Helper.current_wikipub_host(request)
            params[:back_url] = Helper.prepend_with('http://', wikipub_host) unless wikipub_host.blank?
            original_successful_authentication(user)
          end

        end
      end
    end

    # end of module Patches
  end
end
