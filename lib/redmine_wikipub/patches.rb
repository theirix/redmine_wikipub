require_dependency 'redmine/menu_manager'
require_dependency 'redmine/themes'
require_dependency 'application_helper'
require_dependency 'mailer'
require_dependency 'auth_source'
require_dependency 'account_controller'

module RedmineWikipub
  module Patches

    # Patch routes for matched host
    class RoutesPatch
      class << self

        # Patch routing table
        def prepend
          Config::entries.each do |ce|
            Rails.application.routes.prepend do
              constraints(lambda { |req| RedmineWikipub::Helper.find_current_entry(ce, req) }) do
                match "projects/#{ce.project}" => redirect("/projects/#{ce.project}/wiki"), via: [:get, :post]
                match "projects/#{ce.project}/activity" => redirect("/projects/#{ce.project}/wiki"), via: [:get, :post]
                match "projects", :to => redirect('/'), via: [:get, :post]
                match "/", :to => redirect("/projects/#{ce.project}/wiki"), via: [:get, :post]
              end
            end
          end
        end

      end
    end

    # Patch MenuHelper method
    # request only exists within helper so we cannot just patch MenuNode::allowed?
    module MenuHelperPatch
      def self.included(base)
        base.class_eval do

          alias_method :original_menu_items_for, :menu_items_for

          def wikipub_allowed?(node, project)
            if respond_to?(:request) && request
              entries = Helper.find_current_entries(request)
              if !entries.empty?
                allowaccount = entries.any? { |entry| entry.allowaccount? }
                if !project || entries.any? { |entry| project.name == entry.project }
                  if node && Helper.excluded_menu_names(allowaccount).include?(node.name)
                    return false
                  end
                end
              end
            end
            return true
          end

          # note: method is copied from lib/redmine/menu_manager.rb
          # must be syncronized with redmine
          def menu_items_for(menu, project=nil)
            items = []
            Redmine::MenuManager.items(menu).root.children.each do |node|
              if node.respond_to?(:allowed?)
                is_allowed = node.allowed?(User.current, project)
              else
                is_allowed = allowed_node?(node, User.current, project)
              end
              if is_allowed && wikipub_allowed?(node, project)
                if block_given?
                  yield node
                else
                  items << node  # TODO: not used?
                end
              end
            end
            return block_given? ? nil : items
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
            theme_id = nil
            if request
              entry = Helper.find_current_entry_any(request)
              theme_id = String.new(entry.theme) if entry
            end
            theme_id = String.new(Setting.ui_theme) unless theme_id
            # Rails.logger.debug("Check theme #{theme_id}, #{Setting.ui_theme}") if Rails.logger && Rails.logger.debug?
            @current_theme = Redmine::Themes.theme(theme_id)
          end

        end
      end
    end


    # Patch to provide a link to wikipub host in the registration e-mail
    # There is no request object in a Mailer
    module MailerPatch
      def self.included(base)
        base.class_eval do

          alias_method :original_account_information, :account_information

          def account_information(user, password)
            # hacky solution to check whether this call is from MailHandler
            if called_from_mailhandler?
              wikipub_host = Config::entries.empty? ? '' : Config::entries.first.hostname
              Rails.logger.debug("Patched account_information for host #{wikipub_host}") if Rails.logger && Rails.logger.debug?

              set_language_if_valid user.language
              @user = user
              @password = password
              if wikipub_host.blank?
                @login_url = url_for(:controller => 'account', :action => 'login')
              else
                @login_url = url_for(:host => wikipub_host, :controller => 'account', :action => 'login')
              end
              m = mail :to => user.mail,
                :subject => l(:mail_subject_register, wikipub_host) do |format|
                format.text { render 'account_information_wikipub' }
                format.html { render 'account_information_wikipub' } unless Setting.plain_text_mail?
              end
              if !m.from.first.index('<')
                m.from = "#{Helper.extract_host(wikipub_host)} <#{m.from.first}>"
              end
              m
            else
              Rails.logger.debug("Original account_information") if Rails.logger && Rails.logger.debug?
              original_account_information(user,password)
            end
          end

          private

          def called_from_mailhandler?
            caller_locations.any? do |backtr|
              backtr.label == 'receive' && File.basename(backtr.path) == 'mail_handler.rb'
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
            wikipub_host = request ? Helper.current_wikipub_host(request) : nil

            if !wikipub_host.blank? && respond_to?(:request) && request
              # redirect to root if default login succeeded (i.e. simple login) instead of /mypage
              if request.env['HTTP_REFERER'] == url_for(:controller => 'account', :action => 'login')
                back_url = Helper.prepend_with('http://', wikipub_host)
              else
                # redirect to actual referer if one is specified
                if !request.env['HTTP_REFERER'].blank?
                  uri = URI.parse(CGI.unescape(request.env['HTTP_REFERER']))
                  back_url = CGI.parse(uri.query)['back_url'].first if uri.query
                end
              end

              if back_url
                params[:back_url] = back_url.to_s
                Rails.logger.debug("Patched back_url is #{params[:back_url]}") if Rails.logger && Rails.logger.debug?
              end
            end
            original_successful_authentication(user)
          end

        end
      end
    end

    # end of module Patches
  end
end
