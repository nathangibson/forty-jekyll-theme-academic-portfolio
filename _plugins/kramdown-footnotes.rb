class Kramdown::Converter::Html

  require 'kramdown/element'
    # Overriding lib/kramdown/converter/html.rb, line 487

    def footnote_content
        ol = Kramdown::Element.new(:ol)
        ol.attr['start'] = @footnote_start if @footnote_start != 1
        i = 0
        backlink_text = escape_html(@options[:footnote_backlink], :text)
        while i < @footnotes.length
          name, data, _, repeat = *@footnotes[i]
          li = Kramdown::Element.new(:li, nil, 'id' => "fn:#{name}", 'role' => 'doc-endnote')
          li.children = Marshal.load(Marshal.dump(data.children))

          para = nil
          if li.children.last.type == :p || @options[:footnote_backlink_inline]
            parent = li
            while !parent.children.empty? && ![:p, :header].include?(parent.children.last.type)
              parent = parent.children.last
            end
            para = parent.children.last
            insert_space = true
          end

          unless para
            li.children << (para = Kramdown::Element.new(:p))
            insert_space = false
          end

          unless @options[:footnote_backlink].empty?
            nbsp = entity_to_str(ENTITY_NBSP)
            value = sprintf(FOOTNOTE_BACKLINK_FMT, (insert_space ? nbsp : ''), name, backlink_text)
            para.children << Kramdown::Element.new(:raw, value)
            (1..repeat).each do |index|
              value = sprintf(FOOTNOTE_BACKLINK_FMT, nbsp, "#{name}:#{index}",
                              "#{backlink_text}<sup>#{index + 1}</sup>")
              para.children << Kramdown::Element.new(:raw, value)
            end
          end

          ol.children << Kramdown::Element.new(:raw, convert(li, 4)) # Actually creates li elements
          i += 1
        end
        if ol.children.empty?
          ''
        else
          format_as_indented_block_html('div', {class: "footnotes side-notes", role: "doc-endnotes"}, convert(ol, 2), 0)
        end
    end

    

  # File lib/kramdown/converter/html.rb, line 371
  def convert_root(el, indent)
    result = inner(el, indent)
    # query = result.scan(/<p.*?<\/p>|<h\d.*?<\/h\d>/m)
    if @footnote_location
      result.sub!(/#{@footnote_location}/, footnote_content.gsub(/\\/, "\\\\\\\\"))
    else
      result << footnote_content
    end
    if @toc_code
      toc_tree = generate_toc_tree(@toc, @toc_code[0], @toc_code[1] || {})
      text = if !toc_tree.children.empty?
              convert(toc_tree, 0)
            else
              ''
            end
      result.sub!(/#{@toc_code.last}/, text.gsub(/\\/, "\\\\\\\\"))
    end
    # need to take care of numbering and multiple footnotes per paragraph
    # Also substitute in any variables and make readable.
    # Or use .scan with arrays and regex groups to get it
    # result.gsub(/(fn:(\d+).*?<\/(p|h\d)>)/m,'\1'+'<ol class="side-notes">'+footnote_content.scan(/<li id=.*?<\/li>/m)['\2'.to_i].to_s+'</ol>')
    before_footnote = '^(.*?(?=fn:))?'
    between_footnotes = '(fn:(\d+).*?(?=fn:))' # How to allow multiple? * doesn't seem to work
    after_footnote = '(fn:(\d+).*?<\/[ph]\d?>)' # How to allow multiple? * doesn't seem to work
    any = '(.+)'
    text_by_footnotes = result.scan(/#{before_footnote}#{between_footnotes}#{after_footnote}#{any}/m)
    start_tree = '(<div.*?<ol>\s+)'
    footnote = '(<li.*?fn:(\d+).*?<\/li>\s*)*'
    footnotes_split = footnote_content.scan(/#{start_tree}#{footnote}/m)
    result + text_by_footnotes.to_s + footnotes_split.to_s
  end

end