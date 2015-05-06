module RedmineWikipub

  class AnalyticsHooks < Redmine::Hook::ViewListener

    def view_layouts_base_body_bottom(context = { })
      entry = Helper.find_current_entry_any(context[:request])
      if entry && entry.analytics && !entry.analytics.empty?
        return entry.analytics
      else
        if (Config.default_analytics or "").empty?
          return ""
        else
          return Config.default_analytics
        end
      end
    end
  end

end
