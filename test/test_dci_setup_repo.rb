# frozen_string_literal: true
#
# Copyright (C) 2016 Harald Sitter <sitter@kde.org>
# Copyright (C) 2016 Bhushan Shah <bshah@kde.org>
# Copyright (C) 2016 Rohan Garg <rohan@kde.org>
# Copyright (C) 2021 Scarlett Moore <sgmoore@kde.org>
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

require_relative '../dci/lib/setup_repo'
require_relative 'lib/testcase'

require 'mocha/test_unit'
require 'webmock/test_unit'

class DCISetupRepoTest < TestCase
  def setup
    # Reset caching.
    Apt::Repository.send(:reset)
    # Disable bionic compat check (always assume true)
    Apt::Repository.send(:instance_variable_set, :@disable_auto_update, true)
    # Disable automatic update
    Apt::Abstrapt.send(:instance_variable_set, :@last_update, Time.now)
    # Make sure $? is fine before we start!
    reset_child_status!
    # Disable all web (used for key).
    WebMock.disable_net_connect!
    ENV['SERIES'] = 'next'
    ENV['RELEASE_TYPE'] = 'desktop'
    ENV['RELEASE'] = 'netrunner-desktop'
    ENV['TYPE'] = 'stable'
    @prefix = 'netrunner'
    @series = ENV.fetch('SERIES')
    @release_type = ENV.fetch('RELEASE_TYPE')
    @release = ENV.fetch('RELEASE')
    @dist = "#{@release}-#{@series}"
    @components = [DCI.get_release_data(@release_type, @release)['components']]
  end

  def teardown
    Apt::Repository.send(:reset)

    WebMock.allow_net_connect!
    ENV['SERIES'] = nil
    ENV['RELEASE_TYPE'] = nil
    ENV['RELEASE'] = nil
    ENV['TYPE'] = nil
    @prefix = ''
    @dist = ''
    @components = []
  end

  def test_setup_i386!
    setup
    Object.any_instance.expects(:system)
          .with('dpkg --add-architecture i386')
          .returns(true)
    DCI.setup_i386!
    teardown
  end

  def test_setup_backports!
    setup
    system_calls = [
      ["apt-get", "-y", "-o", "APT::Get::force-yes=true", "-o", "Debug::pkgProblemResolver=true", "-q", "install", "software-properties-common"],
      ['add-apt-repository', '--no-update', '-y', 'deb http://deb.debian.org/debian stable-backports main'],
      ['apt-get', *Apt::Abstrapt.default_args, 'update'],
      ['apt-get', *Apt::Abstrapt.default_args, 'upgrade', '-t=stable-backports']
    ]
    system_sequence = sequence('system-calls')
    system_calls.each do |cmd|
      Object.any_instance.expects(:system)
            .with(*cmd)
            .returns(true)
            .in_sequence(system_sequence)
    end
    DCI.setup_backports!
    teardown
  end

  def test_add_repos
    setup
    system_calls = [
      ["apt-get", *Apt::Abstrapt.default_args, "install", "software-properties-common"],
      ['add-apt-repository', '--no-update', '-y', 'deb http://dci.ds9.pub/netrunner netrunner-desktop-next netrunner extras artwork common backports netrunner-core netrunner-desktop']
    ]
    system_sequence = sequence('system-calls')
    system_calls.each do |cmd|
      Object.any_instance.expects(:system)
            .with(*cmd)
            .returns(true)
            .in_sequence(system_sequence)
    end
    DCI.add_repos(@prefix, @dist, @components)
    teardown
  end

  def test_setup_repo!
    setup
    system_calls = [
      ['apt-get', *Apt::Abstrapt.default_args, 'update'],
      ['apt-get', *Apt::Abstrapt.default_args, 'upgrade'],
      ['dpkg --add-architecture i386'],
      ['apt-get', *Apt::Abstrapt.default_args, 'install', 'software-properties-common'],
      ['add-apt-repository', '--no-update', '-y', 'deb http://deb.debian.org/debian stable-backports main'],
      ['apt-get', *Apt::Abstrapt.default_args, 'update'],
      ['apt-get', *Apt::Abstrapt.default_args, 'upgrade', '-t=stable-backports'],
      ['add-apt-repository', '--no-update', '-y', 'deb http://dci.ds9.pub/netrunner netrunner-desktop-next netrunner extras artwork common backports netrunner-core netrunner-desktop'],
    ]
    system_sequence = sequence('system-calls')
    system_calls.each do |cmd|
      Object.any_instance.expects(:system)
            .with(*cmd)
            .returns(true)
            .in_sequence(system_sequence)
    end
    assert_equal('netrunner', @prefix)
    assert_equal('netrunner-desktop', @release)
    assert_equal(['netrunner extras artwork common backports netrunner-core netrunner-desktop'], @components)

    key_catcher = StringIO.new
    IO.expects(:popen)
      .with(['apt-key', 'add', '-'], 'w')
      .yields(key_catcher)
      .returns(true)
    DCI.setup_repo!
    teardown
  end
end
