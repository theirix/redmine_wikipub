module RedmineWikipub
  
  class Helper
    def self.check_config
      Rails.logger.debug("Wikipub settings: host=#{Config::settings_hostname} project=#{Config::settings_project}") if logger && logger.debug?
    end
  end
end