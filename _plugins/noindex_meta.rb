# frozen_string_literal: true

Jekyll::Hooks.register [:pages, :documents], :post_render do |page|
  next unless page.output_ext == ".html"
  next unless page.data["noindex"]

  robots_meta = '<meta name="robots" content="noindex">'
  next if page.output.include?(robots_meta)

  page.output = page.output.sub("<head>", "<head>\n    #{robots_meta}")
end
