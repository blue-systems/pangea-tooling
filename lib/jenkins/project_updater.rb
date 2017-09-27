# frozen_string_literal: true
#
# Copyright (C) 2014-2016 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) version 3, or any
# later version accepted by the membership of KDE e.V. (or its
# successor approved by the membership of KDE e.V.), which shall
# act as a proxy defined in Section 6 of version 3 of the license.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require 'fileutils'
require 'jenkins_junit_builder'
require 'logger'
require 'logger/colors'

require_relative '../../ci-tooling/lib/thread_pool'

module Jenkins
  # Updates Jenkins Projects
  class ProjectUpdater
    module JUnit
      NOT_TEMPLATED = :not_templated
      NOT_REMOTE = :not_remote

      # Wrapper converting an ADT summary into a JUnit suite.
      class Suite
        # Wrapper converting an ADT summary entry into a JUnit case.
        class Case < JenkinsJunitBuilder::Case
          TYPED_OUTPUT = {
            NOT_TEMPLATED => <<-EOF,
This job was found in Jenkins but it is not being generated by the updater.
Chances are the job was manually created and never moved to automatic provisioning.
Not having jobs automatically provisioned excludes them from automated adjustments,
plugin installation, discoverability etc.
The job must be moved to pangea-tooling's job templating system.

If this job is a merger or build job it could be that either it is intended to be
removed in which case the related jobs should get deleted from jenkins. It is
also possible that the templatification regressed because the relevant project
entry disappeared from the config(s) or the project wildcard detection is not
working becuase the relevant branch in the Git repository is missing.

https://github.com/blue-systems/pangea-conf-projects
            EOF
            NOT_REMOTE => <<-EOF
The job should have been generated in Jenkins as we had it in our creation queue,
but we did not find it. Chances are the creation failed.
Check the detailed output to find output relating to the failed creation of the job.
            EOF
          }.freeze

          def initialize(name, type)
            self.classname = @name
            # 3rd and final drill down CaseClassName
            self.name = name
            self.time = 0
            self.result = JenkinsJunitBuilder::Case::RESULT_FAILURE
            system_out.message = TYPED_OUTPUT.fetch(type)
          end
        end

        TYPED_CLASSNAMES = {
          NOT_TEMPLATED => 'NotTemplated',
          NOT_REMOTE => 'FailedToCreate'
        }.freeze

        def initialize(type, delta)
          @suite = JenkinsJunitBuilder::Suite.new
          # This is not particularly visible in Jenkins, it's only used on the
          # testcase page itself where it will refer to the test as
          # SuitePackage.CaseClassName.CaseName (from SuitePackage.SuiteName)
          @suite.name = 'ProjectUpdater'
          # Primary sorting name on Jenkins.
          # Test results page lists a table of all tests by packagename
          @suite.package = TYPED_CLASSNAMES.fetch(type)
          delta.each { |job| @suite.add_case(Case.new(job, type)) }
        end

        def write_into(dir)
          unless ENV.include?('JENKINS_URL')
            puts 'not writing junit output as this is not a jenkins build'
            return
          end
          FileUtils.mkpath(dir) unless Dir.exist?(dir)
          File.write("#{dir}/#{@suite.package}.xml", @suite.build_report)
        end
      end
    end

    attr_accessor :log

    def initialize
      update_submodules
      @job_queue = Queue.new
      @job_names = []
      @log = Logger.new(STDOUT)
    end

    def update_submodules
      Dir.chdir(File.realpath("#{__dir__}/../../")) do
        return if @submodules_updated
        unless system(*%w[git submodule update --remote --recursive])
          raise 'failed to update git submodules of tooling!'
        end
        @submodules_updated = true
      end
    end

    def update
      update_submodules
      populate_queue
      run_queue
      if ENV.include?('UPDATE_INCLUDE')
        warn 'Skipping job creation validation as UPDATE_INCLUDE is set'
      else
        check_jobs_exist
      end
    end

    def install_plugins
      # Autoinstall all possibly used plugins.
      installed_plugins = Jenkins.plugin_manager.list_installed.keys
      plugins = (plugins_to_install + standard_plugins).uniq
      plugins.each do |plugin|
        next if installed_plugins.include?(plugin)
        puts "--- Installing #{plugin} ---"
        Jenkins.plugin_manager.install(plugin)
      end
    end

    private

    # Override to supply a blacklist of jobs to not be considered in the
    # templatification warnings.
    def jobs_without_template
      []
    end

    def check_jobs_exist
      # To blacklist jobs from being complained about, override
      # #jobs_without_template in the sepcific updater class.

      remote = JenkinsApi::Client.new.job.list_all - jobs_without_template
      local = @job_names

      names = remote - local
      job_warn('--- Some jobs are not being templated! ---', names)
      JUnit::Suite.new(JUnit::NOT_TEMPLATED, names).write_into('reports/')
      names = local - remote
      job_warn('--- Some jobs were not created @remote! ---', (local - remote))
      JUnit::Suite.new(JUnit::NOT_REMOTE, names).write_into('reports/')
    end

    def job_warn(warning_str, names)
      return if names.empty?
      log.warn warning_str
      names.each do |name|
        uri = JenkinsApi::Client.new.uri
        uri.path += "/job/#{name}"
        log.warn name
        log.warn "    #{uri.normalize}"
      end
      log.warn '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    end

    def all_template_files
      Dir.glob('jenkins-jobs/templates/**/**.xml.erb')
    end

    # Standard plugins not showing up in templates but generally useful to have
    # for our CIs. These should as a general rule not change behavior or
    # add functionality or have excessive depedencies as to not slow down
    # jenkins for no good reason.
    def standard_plugins
      %w[
        greenballs
        status-view
        simple-theme-plugin
      ]
    end

    # FIXME: this installs all plugins used by all CIs, not the ones at hand
    def plugins_to_install
      plugins = []
      installed_plugins = Jenkins.plugin_manager.list_installed.keys
      all_template_files.each do |path|
        File.readlines(path).each do |line|
          match = line.match(/.*plugin="(.+)".*/)
          next unless match&.size == 2
          plugin = match[1].split('@').first
          next if installed_plugins.include?(plugin)
          plugins << plugin
        end
      end
      plugins.uniq.compact
    end

    def enqueue(obj)
      @job_queue << obj
      @job_names << obj.job_name
      obj
    end

    def run_queue
      BlockingThreadPool.run do
        until @job_queue.empty?
          job = @job_queue.pop(true)
          job.update(log: log)
        end
      end
    end
  end
end
