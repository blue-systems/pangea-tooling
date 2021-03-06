# frozen_string_literal: true
require_relative '../job'

# publisher
class DCIPublisherJob < JenkinsJob
  attr_reader :release
  attr_reader :series
  attr_reader :dependees
  attr_reader :artifact_origin
  attr_reader :downstream_triggers
  attr_reader :basename
  attr_reader :repo
  attr_reader :component
  attr_reader :architecture

  def initialize(basename, release:, series:, dependees:, component:, upload_map:, architecture:)
    super("#{basename}_#{architecture}_pub", 'dci_publisher.xml.erb')
    @release = release
    @series = series
    @dependees = dependees
    @artifact_origin = "#{basename}_#{architecture}_bin"
    @downstream_triggers = []
    @basename = basename
    @component = component
    @architecture = architecture
    @repo_names = []

    if upload_map
      @repo = upload_map[@component]
      @repo ||= upload_map['default']
    end
  end

  def repo_names
    @repo_names = ["#{component}-#{series}"]
    @repo_names
  end


  def aptly_resources
    @repo_names.size > 1 ? 0 : 1
  end

  def append(job)
    @downstream_triggers << job
  end
end
