# frozen_string_literal: true
#
# Copyright (C) 2015-2016 Harald Sitter <sitter@kde.org>
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

require_relative 'job'

# Progenitor is the super super super job triggering everything.
class MgmtProgenitorJob < JenkinsJob
  attr_reader :daily_trigger
  attr_reader :downstream_triggers
  attr_reader :dependees
  attr_reader :blockables

  def initialize(downstream_jobs:, dependees: [], blockables: [])
    super('mgmt_progenitor', 'mgmt-progenitor.xml.erb')
    @daily_trigger = '0 0 * * *'
    @downstream_triggers = downstream_jobs.collect(&:job_name)
    @dependees = dependees.collect(&:job_name)
    @blockables = blockables.collect(&:job_name)
  end
end
