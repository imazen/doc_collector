require 'rugged'
require 'yaml'
require 'pathname'
module DocCollector
  class Collector


    def self.for_working_copy(working_copy)
      Collector.new(Rugged::Repository.new(working_copy))
    end

    def initialize(rugged_repository)
      @git = rugged_repository
    end

    def load_branches_yaml
      ref = @git.branches["master"]
      master_head_commit = @git.lookup(ref.target_id)
      blob = master_head_commit.tree.path("docs/collect_branches.yml")
      text_contents = blob.read_raw.data
      collect_branches_config = YAML.load(text_contents)

      @errors ||= []
      @errors << "The following branches are specified in collect_branches.yml, but do not exist: " + (", " * unfiltered_branches.select{|b| !b.exists?}.select{|b| b.name})
      unfiltered_branches = collect_branches_config.map{ |c| Branch.new(@git, c["branch"], c.delete_if{|k,v| k == "branch"})}
      @branches = unfiltered_branches.select{|b| b.exists?}

    end 

    def read_from_branches
      @branches.each do |b|
        b.load_configuration
        b.load_input_files
      end 
    end

    def branch(branch_name)
      @branches.select{|b| b.name == branch_name}.first
    end

    def produce_combined_output
      combined = {}
      existing_aliases = Set.new
      branches.reverse.each do |b|
        b.load_configuration
        b.load_input_files
        b.produce_output.each do |p|
          higher_level_path = Pathname.new(b.subfolder).join(p.path).cleanpath
          combined[higher_level_path] = p

          #Prevent conflicting aliases
          if existing_aliases.intersect?(p.aliases)
            p.meta.aliases = p.meta.aliases.subtract(existing_aliases)
          end
          existing_aliases.merge(p.aliases)
        end
        @errors.merge(b.errors)
      end

      @combined ||= combined
    end 

    def write_output_to(folder_name)
      produce_combined_output.each do |path, page|
        File.open(File.join(folder_name, path), 'w') do  |file| 
          file.write(page.serialize_with_yaml)
        end
      end
    end
  end
end