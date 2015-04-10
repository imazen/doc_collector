require "bundler/gem_tasks"
require "doc_collector"

task :syntax do
  Dir[File.join('**', '*.rb')].each do |ruby_file|
    `ruby -c #{ruby_file}`
  end
end

task :try do
 coll = DocCollector::Collector.for_working_copy("../doc_collector-sample_input")
 coll.load_branches_yaml
 coll.read_from_branches
 coll.write_output_to("../doc_collector-sample_output")
end

