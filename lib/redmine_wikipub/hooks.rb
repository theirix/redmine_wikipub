module RedmineWikipub

  class AnalyticsHooks < Redmine::Hook::ViewListener

    def view_layouts_base_body_bottom(context = { })
			entry = Helper.find_current_entry_any(context[:request])
      if entry && entry.analytics && !entry.analytics.empty?
        return entry.analytics
      else
        return ""
      end
    end
  end

end