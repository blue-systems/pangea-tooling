source 'https://rubygems.org'

gem 'aptly-api', '>= 0.5.0'
gem 'concurrent-ruby'
gem 'deep_merge', '~> 1.0'
gem 'docker-api', '~> 1.24' # Container.refresh! only introduced in 1.23
gem 'gir_ffi'
gem 'git'
gem 'gitlab',
    git: 'https://github.com/NARKOZ/gitlab',
    branch: 'master'
gem 'insensitive_hash'
gem 'jenkins_api_client'
gem 'jenkins_junit_builder'
gem 'logger-colors'
gem 'mercurial-ruby'
gem 'net-ping', '< 2.0.0'
gem 'net-sftp'
gem 'net-ssh-gateway'
gem 'nokogiri'
gem 'oauth', '~> 0.4'
gem 'octokit'
gem 'releaseme',
    git: 'git://anongit.kde.org/releaseme.git',
    branch: 'master'
gem 'rugged'

# Temporarily from git waiting for a release newer than 4.1.0. Once a newer
# version is available this can move up and drop the git paramaters.
gem 'net-ssh', '<= 4.1.0',
    git: 'https://github.com/net-ssh/net-ssh',
    branch: 'master'

# Git URI management
gem 'git_clone_url', '~> 2.0'
gem 'uri-ssh_git', '~> 2.0'

# Test logging as junit (also used at runtime for linting)
gem 'ci_reporter_test_unit',
    git: 'https://github.com/apachelogger/ci_reporter_test_unit',
    branch: 'test-unit-3'
gem 'test-unit', '~> 3.0'

group :development, :test do
  gem 'equivalent-xml'
  gem 'mocha'
  gem 'net-scp'
  gem 'parallel_tests'
  gem 'rack'
  gem 'rake', '~> 12.0'
  gem 'rake-notes'
  gem 'rubocop', '>= 0.38'
  gem 'rubocop-checkstyle_formatter'
  gem 'ruby-progressbar'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'terminal-table'
  gem 'vcr', '>= 3.0.1'
  gem 'webmock'
end

group :s3 do
  gem 'aws-sdk-v1'
end
