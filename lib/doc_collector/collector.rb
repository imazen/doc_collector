require 'rugged'
require 'yaml'
require 'pathname'
require 'fileutils'
module DocCollector
  class Collector


    def self.for_working_copy(working_copy)
      Collector.new(Rugged::Repository.new(working_copy))
    end

    def initialize(rugged_repository)
      @git = rugged_repository
      @errors = []
    end

    def load_branches_yaml
      ref = @git.branches["master"]
      master_head_commit = @git.lookup(ref.target_id)
      blob = master_head_commit.tree.path("docs/collect_branches.yml")
      text_contents = @git.lookup(blob[:oid]).content
      collect_branches_config = YAML.load(text_contents)

      unfiltered_branches = collect_branches_config["branches"].map{ |c| Branch.new(@git, c["branch"], c.delete_if{|k,v| k == "branch"})}

      missing_branches = unfiltered_branches.select{|b| !b.exists?}

      @errors << "The following branches are specified in collect_branches.yml, but do not exist: " + (missing_branches.map{|b| b.name} * ", ") unless missing_branches.empty?
      
      @branches = unfiltered_branches.select{|b| b.exists?}

    end 

    def read_from_branches
      @branches.each do |b|
        b.load_configuration
        b.load_input_files
      end 
    end
    attr_reader :branches
    def branch(branch_name)
      @branches.select{|b| b.name == branch_name}.first
    end

    def produce_combined_output
      combined = Hardwired::CaseInsensitiveHash.new
      existing_aliases = Set.new

      versions_of = Hardwired::CaseInsensitiveHash.new
      branches.reverse.each do |b|
        b.load_configuration
        b.load_input_files
        b.produce_output[:pages].each{|p| versions_of[p.path] ||= []; versions_of[p.path] << b.subfolder}
      end
      branches.reverse.each do |b|
        output = b.produce_output
        output[:pages].each do |p|
          higher_level_path = Pathname.new(b.subfolder).join(p.path).cleanpath.to_s
          combined[higher_level_path] = p
          alias_set = Set.new(p.aliases)
          # We no longer use versions - p.meta.versions = versions_of[p.path]
          #Prevent conflicting aliases
          if existing_aliases.intersect?(alias_set)
            p.meta.aliases = alias_set.subtract(existing_aliases).to_a
            #Take conflicting aliases as a sign that we should not index
            p.add_flag("-sitemap")
          end
          existing_aliases.merge(p.aliases)
        end
        output[:file_writes].each do |w|
          higher_level_path = Pathname.new(b.subfolder).join(w[:to]).cleanpath.to_s
          combined[higher_level_path] = w[:contents]
        end

        @errors.concat(b.errors)
      end

      @combined ||= combined
      combined
    end 

    def write_output_to(folder_name)
      out = produce_combined_output
      #puts out
      out.each do |path, page|
        full_path = File.join(folder_name, path.to_s)
        
        FileUtils::mkdir_p(File.dirname(full_path))
        File.open(full_path, 'w') do  |file| 
          file.write(page.is_a?(String) ? page : page.serialize_with_yaml)
        end
      end
      puts @errors
    end
  end
end