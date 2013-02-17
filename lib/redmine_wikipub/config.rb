module RedmineWikipub
  
  class Config
    def self.bootstrap
      Helper::check_config
    end
  end
end