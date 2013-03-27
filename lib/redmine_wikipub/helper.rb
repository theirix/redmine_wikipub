require 'application_helper'

module RedmineWikipub

  class Helper
    def self.host_satisfied? request
      %w{HTTP_HOST HTTP_X_FORWARDED_HOST}.any? { |header_name| check_header_host(request.env[header_name]) }
    end

    def self.current_wikipub_host request
      check_header_host(request.env['HTTP_HOST']) || check_header_host(request.env['HTTP_X_FORWARDED_HOST'])
    end

    def self.prepend_with prefix, s
      s.starts_with?(prefix) ? s : (prefix + s)
    end

    # Returns whether request is performed against choosen host
    def self.check_header_host value
      begin
        if !value.blank? && !Config::settings_hostname.blank?
          uri_str = prepend_with('http://', value.dup)
          host = URI.parse(uri_str).host
          host if host =~ /#{Config::settings_hostname}/
        end
      rescue Error => e
        Rails.logger.warn("Host check failed with #{e}") if Rails.logger && Rails.logger.warn?
      end
    end

    def self.excluded_menu_names with_account
      categories = [:project_menu, :top_menu]
      categories << :account_menu unless with_account
      allowed_nodes = [ :root, :home ]
      allowed_nodes += [ :issues, :new_issue, :wiki ] if User.current.logged?
      categories.map do |menu_type|
        Redmine::MenuManager.items(menu_type).map { |m| m.name }
      end.flatten.select { |m| !allowed_nodes.include?(m) }
    end

  end

end

