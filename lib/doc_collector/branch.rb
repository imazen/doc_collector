require 'rugged'
require 'yaml'
module DocCollector
  class Branch
    def initialize(repo, branch_name, meta)
      @branch_meta = meta
      @git = repo
      @name = branch_name
      @ref =  @git.branches[name]
      @tree =  @git.lookup(@ref.target_id).tree unless @ref.nil?
      @errors = []
    end 

    attr_accessor :order

    attr_reader :name, :branch_meta, :tree, :errors

    def exists?
      !@tree.nil?
    end

    def search_patterns
      @collect_files_config["patterns"]
    end 

    def collect_files_array
      @collect_files_config["files"]
    end 
    def metadata_to_apply
      collect_files_array.select{|set| !set.has_key?("from") }
    end
    def splitting_to_perform
      collect_files_array.select{|set| set.has_key?("render_and_split") }
    end 

    def load_configuration
      
      blob = tree.path("docs/collect_files.yml")
      raise "Branch #{name} is missing docs/collect_files.yml" if blob.nil?
      
      text_contents = blob.read_raw.data
      @collect_files_config = YAML.load(text_contents)
    end

   
    def load_input_files
      file_set = {}
      found = []
      tree.walk_blobs(:postorder) do |root, e|
        if search_patterns.any?{ |p| File.fnmatch(p, root) }
          file = {from: root, rawdata: @git.lookup(e[:oid]).read_raw.data}
          found << file
          file_set[root] = file
        end
      end

      mentioned = []
      collect_files_array.each do |f|
        from = f["from"]
        blob = tree.path(from)
        if blob.nil?
          errors << "Branch #{name} does not contain #{from}"
          next
        end
        m = {from: from, rawdata: blob.read_raw.data, meta: f}
        f.delete_if?{|k,v| ["from"]} #Remove parsed stuff from meta

        mentioned << m
        file_set[from] = m #Hopefully this means we overwrite the equivalent 
      end

      file_set.each do |k, file|
        raw_contents = file[:rawdata]
        begin
          meta, markup, has_meta = MetadataParsing.extract(raw_contents)
        rescue Psych::SyntaxError
          @errors << "Invalid front-matter metadata in #{k}, branch #{name} \n #{$!}"
        end
        file[:meta].merge!(meta) if has_meta#merge the file and the .yml metadata, .yml wins

        file[:meta]["edit_info"] = "#{name}/#{k}" #so we can make an edit page button 
        file[:markup] = markup
      end

      @input = file_set
    end 

    def produce_output_copy

      output = @input.clone
      split = {}
      normal_by_target = {}
      @input.each  do |k,v| 
        if v[:meta]["render_and_split"]
          split[k] = v
        else
          target = v[:meta]["to"] || v[:from]
          normal_by_target[target] = v
        end
      end
      split.each do |path, file|

        splitter = RenderSplit.new
        details = file[:meta]["render_and_split"]
        raise "Convention-based splitting not yet supported. #{path} branch #{name}" if (details == true)
        details.each do |target|
          new_markup = extract_html_from_gfm(file[:markup], target["start_at"], target["stop_before"])
          new_metadata = target.select{|k,_| !["start_at", "stop_before"].include?(k)}
          new_metadata = file[:meta].select{|k,_| !["render_and_split"].include?(k)}.merge(new_metadata)
          normal_by_target[new_metadata["to"]] = {meta: new_metadata, markup: new_markup}
        end
        
      end

      normal_by_target.to_a.map do |pair|
        new_raw_text = YAML.dump(pair[1][:meta]) + "---\n\n" + pair[1][:markup]
        t = Hardwired::Template.new(nil, pair[0], new_raw_text)
        t.is_page? ? Page.new(t) : t
        #{path: pair[0], data: pair[1]}
      end
    end

    def produce_output
      @output ||= produce_output_copy
    end


  end
end
