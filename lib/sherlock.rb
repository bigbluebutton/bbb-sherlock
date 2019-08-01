# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
#


path = File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
$LOAD_PATH << path

require 'sherlock/akka_apps'
require 'sherlock/html5_client'
require 'sherlock/util'

module Sherlock
  # Sherlock logs information about its progress.
  # Replace with your own logger if you desire.
  #
  # @param [Logger] log your own logger
  # @return [Logger] the logger you set
  def self.logger=(log)
    @logger = log
  end

  # Get Sherlock logger.
  #
  # @return [Logger]
  def self.logger
    return @logger if @logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    @logger = logger
  end

  def self.errlogger=(log)
    @errlogger = log
  end

  def self.errlogger
    return @errlogger if @errlogger
    errlogger = Logger.new(STDOUT)
    errlogger.level = Logger::WARN
    @errlogger = errlogger
  end
end
