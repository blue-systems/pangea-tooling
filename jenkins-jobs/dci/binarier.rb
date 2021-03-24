# frozen_string_literal: true
require_relative '../job'

# binary builder
class DCIBinarierJob < JenkinsJob
  attr_reader :basename
  attr_reader :type
  attr_reader :series
  attr_reader :architecture
  attr_reader :artifact_origin
  attr_reader :downstream_triggers

  def initialize(basename, type:, series:, architecture:)
    super("#{basename}_#{architecture}_bin", 'dci_binarier.xml.erb')
    @basename = basename
    @type = type
    @series = series
    @architecture = architecture
    @artifact_origin = "#{basename}_#{architecture}_src"
    @downstream_triggers = []
  end

  def trigger(job)
    @downstream_triggers << job.job_name
  end
end
