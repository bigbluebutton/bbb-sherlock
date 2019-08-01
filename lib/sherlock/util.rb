# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#

require 'active_support/core_ext/hash'

module Sherlock
  module Util
    def self.valid_json?(json)
      begin
        JSON.parse(json)
        return true
      rescue Exception => e
        return false
      end
    end

    def self.scrub_line_to_remove_illegal_chars(line)
      # https://stackoverflow.com/questions/24036821/ruby-2-0-0-stringmatch-argumenterror-invalid-byte-sequence-in-utf-8
      line.scrub
    end

    def self.snake_case_keys!(data)
      # Convert CamelCase keys to snake_keys. This is done in bbbevents gem
      # but we do it here too anyways.
      data.deep_transform_keys! do |key|
        k = key.to_s.underscore rescue key
        k.to_sym rescue key
      end
    end
  end
end
