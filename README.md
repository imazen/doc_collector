# DocCollector

Copies files from multiple branches of one repostiory into multiple folders of another. 

Input files can have metadata. Metadata can be overriden by a yaml file in each branch.

Files (like README.md) can be split into multiple output files, if requested by their metadata (or the main yaml file). Start/stop points can either be specified in the metadata as start/end css selctors, or a default convention can be used.

Produced files will contain additional metadata, such as a list of which 'subfolders' contain a similar file (version switching). 


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'doc_collector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install doc_collector

## Usage

DocCollector will read the docs/collect_branches.yml file from the ‘master’ branch of the provided repository. In URL conflicts, the first version listed wins.

```yaml
   branches:
     - branch: develop
       subfolder: docs/latest
      
     - branch: support/v4
       subfolder: docs/v4
      
     - branch: support/v3
       subfolder: docs/v3
```

DocCollector will look at all *.md files in each branch. In addition, it will read docs/collect_files.yml to discover additional files. collect_files.yml can override metadata in individual files.

```yaml
  patterns:
    - "/**/*.md"
  files:
    - path: README.md
      render_and_split:
        - to: getting_started.htmf
          start_at: "a[name='installation']"
          stop_before: "a[name='troubleshooting_guide']"
          heading: Getting Started
    - path: Advanced.md
      render_and_split: true #Use automatic convention, a[name='split-installation'] a[name-'split-installation-stop']

    - path: Plugins/AdvancedFilters/Readme.md
      to: plugins/advancedfilters.md

    - path: Contrib/PdfRenderer/License.md
      to: /licenses/pdfrenderer.md

    - to: /licenses/pdfrenderer.md
      title: PDF renderer licensing
```




## Contributing

1. Fork it ( https://github.com/[my-github-username]/doc_collector/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request