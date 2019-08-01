# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#

require "active_support/core_ext/hash/except"

module AkkaApps
  module Parser
    EVENT_MSG_RE = /^([^ ]+) .* -- (analytics|trace) -- (.*)$/
    AKKA_APPS_START_RE = /^([^ ]+) .*BigBlueButtonActor - started .*$/
    COMPONENT = "akka-apps"

    def self.parse(raw_log)
      scrubbed = Sherlock::Util.scrub_line_to_remove_illegal_chars(raw_log)
      if result = EVENT_MSG_RE.match(raw_log)
        log_date = result[1]
        payload = result[3]
        process(log_date, payload)
      elsif result = AKKA_APPS_START_RE.match(scrubbed)
        log_date = result[1]
        log_data = {
          timestamp: log_date,
          log_code: "akka_apps_started",
          msg: "Akka apps started event."
        }
        puts log_data.to_json
      else
        raise 'Cannot match regex.'
      end
    end

    def self.process(log_date, payload)
      if Sherlock::Util.valid_json?(payload)
        begin
          data = JSON.parse(payload)
          log_code = data['envelope']['name']
          header = data['core']['header']

          log_data = header
          # Remove the name key
          log_data.except!('name')
          # Convert keys to snake_case
          Sherlock::Util.snake_case_keys!(header)
          # Add log_code and timestamp
          log_data[:log_code] = log_code
          log_data[:timestamp] = log_date

          body = data['core']['body']
          # Convert case to snake_case
          Sherlock::Util.snake_case_keys!(body)

          case log_code
            when "PresentationConversionCompletedSysPubMsg"
              # Remove lots of extra data
              pres = body['presentation']
              pres_name = pres['name']
              extra_info = {
                pod_id: body["podId"],
                pres_name: pres_name,
                pres_id: pres["id"],
                is_current: pres["current"],
                num_pages: pres["pages"].length,
                downloadable: pres["downloadable"]
                }
              log_data[:extras] = extra_info
            else
             log_data[:extras] = body
           end

          log_data
         rescue StandardError => msg
          raise msg.to_s
        end
      end
    end
  end
end
