require 'application_helper'

module RedmineWikipub
  
  class Helper
    # Returns whether request is performed against choosen host
    def self.host_satisfied? request
      desired_hostname_regex = Config::settings_hostname
      %w{HTTP_HOST HTTP_X_FORWARDED_HOST}.any? do |header_name|
        begin
          value = request.env[header_name]
          if !value.blank? && !desired_hostname_regex.blank?
            uri_str = value.dup
            uri_str = 'http://' + uri_str unless uri_str.starts_with? 'http://'
            URI.parse(uri_str).host =~ /#{desired_hostname_regex}/
          end
        rescue Error => e
          Rails.logger.warn("Host check failed with #{e}") if Rails.logger && Rails.logger.warn?
          false
        end        
      end
    end
    
    def self.excluded_menu_names with_account
      categories = [:project_menu, :top_menu]
      categories << :account_menu unless with_account
      categories.map do |menu_type|
        Redmine::MenuManager.items(menu_type).map { |m| m.name }
      end.flatten.select { |m| m != :root && m != :home }
    end
    
  end
    
end

