require 'uri'
require 'net/http'
require 'github/markdown'
require 'nokogiri'

module DocCollector
  class RenderSplit

    def cloneBetweenInner(from_set, target_node, a, b)
      b = Nokogiri::XML::NodeSet.new(b.first.document,b) unless b.nil? || b.is_a?(Nokogiri::XML::NodeSet)
      b = nil if !b.nil? && b.empty?
     
      b_ancestors =  b.nil? ? nil : Nokogiri::XML::NodeSet.new(b.first.document,b.map{|e| [e] + e.ancestors.to_a}.flatten)
     
      return :a_notfound if !a.nil? && (!from_set.include?(a) && (from_set & a.ancestors).empty?)
     
      from_set.each do |n|
        #@@nodes_visited += 1
     
        return :b_found if !b.nil? && b.include?(n)
     
        a = nil if a == n
     
        if a.nil? || (n.element? && a.ancestors.include?(n))
     
          if !n.element?
            target_node.add_child(n.dup)
          else
            copy = target_node.document.create_element(n.name, n.attributes)
            target_node.add_child(copy)
          
            result = cloneBetweenInner(n.children, copy, a, b) unless n.children.nil?
     
            if result == :a_found
              a = nil
            end
            if result == :b_found
              return :b_found 
            end
            if result == :a_notfound
              raise "what??"
            end
     
          end
        elsif !n.children.nil? && n.element? && !b_ancestors.nil? && (n.children & b_ancestors).count > 0
          return :b_found
        end
        end
        return :a_found if a.nil?
    end
     
    def cloneBetween(from_set, start_with, end_before_any)
      holder = Nokogiri::HTML::DocumentFragment.new(Nokogiri::HTML::Document.new);
     
      result = cloneBetweenInner(from_set,holder, start_with,end_before_any)
     
      raise ArgumentError.new("start_with was not found in from_set") if result == :a_notfound 
      holder
    end
     
    def initialize()
    end 

    def extract_html_from_gfm(gfm_text,from_css_selctor, until_css_selctor)
      html = GitHub::Markdown.render_gfm(gfm_text);
      doc = Nokogiri::HTML::fragment(html);
      result_dom = extract_dom_fragment(doc, from_css_selctor, until_css_selctor)
      result_dom.to_html
    end 

    def extract_dom_fragment(nokogiri_fragment, from_css_selctor, until_css_selctor)
      start_at = nokogiri_fragment.css(from_css_selctor).first
      end_at = nokogiri_fragment.css(until_css_selctor)
     
      cloneBetween(nokogiri_fragment.children,start_at,end_at)

    end 

    #uri = URI('https://raw.githubusercontent.com/imazen/resizer/master/readme.md')
    #text = Net::HTTP.get(uri).encode('utf-8','UTF-8');

     

  end 
end
