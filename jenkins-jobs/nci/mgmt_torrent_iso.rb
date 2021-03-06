# frozen_string_literal: true
#
# Copyright (C) 2019 Harald Sitter <sitter@kde.org>
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

require_relative 'pipelinejob'

# update torrent for iso with new mirrors (initial torrent generated by iso job)
class MGMTTorrentISOJob < PipelineJob
  attr_reader :distribution
  attr_reader :type
  attr_reader :architecture
  attr_reader :imagename
  attr_reader :metapackage

  def initialize(type:, distribution:, architecture:, imagename:, metapackage:)
    super("mgmt_torrent_iso_#{imagename}_#{distribution}_#{type}_#{architecture}",
          template: 'mgmt_torrent_iso',
          cron: 'H H/3 * * *')
    @distribution = distribution
    @type = type
    @architecture = architecture
    @imagename = imagename
    # Not used at the time of writing, supported for argument consistency with
    # ISO jobs.
    @metapackage = metapackage
  end
end
