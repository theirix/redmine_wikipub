module RedmineWikipub
  
  class Helper
    def self.check_config
      hostname = Setting.plugin_redmine_wikipub['wikipub_hostname']
      Rails.logger.warn "Wikipub hostname #{hostname}"
    end
  end
end