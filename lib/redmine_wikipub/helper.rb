require 'application_helper'

module RedmineWikipub

  class Helper
    def self.current_wikipub_host request
			entry = find_current_entry_any(request)
			entry ? entry.hostname : nil
    end

		def self.find_current_entry ce, request
      check_header_entry(ce, request.env['HTTP_HOST']) || check_header_entry(ce, request.env['HTTP_X_FORWARDED_HOST'])
		end
		
    def self.find_current_entry_any request
      check_header_entry_any(request.env['HTTP_HOST']) || check_header_entry_any(request.env['HTTP_X_FORWARDED_HOST'])
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


	private
    def self.check_header_entry ce, value
        begin
            if !value.blank? && !ce.hostname.blank?
                uri_str = prepend_with('http://', value.dup)
                host = URI.parse(uri_str).host
                ce if host =~ /#{ce.hostname}/
            end
        rescue Error => e
            Rails.logger.warn("Host check failed with #{e}") if Rails.logger && Rails.logger.warn?
        end
    end

    # Checks whether request is performed against choosen host
		# Return value is the matched config::entry
    def self.check_header_entry_any value
		    Config::entries.map { |ce| check_header_entry(ce, value) }.compact.first
    end

		def self.prepend_with prefix, s
      s.starts_with?(prefix) ? s : (prefix + s)
    end


  end

end

