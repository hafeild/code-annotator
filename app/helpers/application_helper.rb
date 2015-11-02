module ApplicationHelper

  DEFAULT_TITLE = "Online Source Code Annotator"

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = DEFAULT_TITLE
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end
end
