module RedmineWikipub
  
  class Helper
    @@excluded_menu_names = nil
    
    def self.check_config
      Rails.logger.debug("Wikipub settings: host=#{Config::settings_hostname} project=#{Config::settings_project}") if Rails.logger && Rails.logger.debug?
    end
    
    # Returns whether request is performed against choosen host
    def self.host_satisfied? request
      desired_hostname = Config::settings_hostname
      %w{HTTP_HOST HTTP_X_FORWARDED_HOST}.any? do |header_name|
        value = request.env[header_name]
        if !value.blank? || desired_hostname.blank?
          value = 'http://' + value unless value.starts_with? 'http://'
          URI.parse(value).host =~ /^#{desired_hostname}$/
        end          
      end
    end
    
    def self.excluded_menu_names
      if @@excluded_menu_names.nil?
        @@excluded_menu_names = [:project_menu, :top_menu, :account_menu].map do |menu_type|
          Redmine::MenuManager.items(menu_type).map { |m| m.name }
        end.flatten.select { |m| m != :root }
      end
      @@excluded_menu_names
    end
    
  end
end