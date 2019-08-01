# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#

module Html5Client
  module Parser
    LINE_RE = /([^ ]*) \[([^\]]*)\] (.*)/

    class NginxLogUnescaper
      NGINX_UNESCAPE_MAP = {}

      256.times do |i|
        h, l = i>>4, i&15
        c = i.chr.freeze
        k = sprintf('\\x%X%X', h, l).freeze
        NGINX_UNESCAPE_MAP[k] = c
      end
      NGINX_UNESCAPE_MAP.freeze

      def self.unescape(str)
        str.b.gsub(/\\x[0-9A-F][0-9A-F]/, NGINX_UNESCAPE_MAP).force_encoding(Encoding::UTF_8)
      end
    end

    def self.pre_proc_client_info(client_info)
      session_token = client_info[:sessionToken]
      meeting_id = client_info[:meetingId]
      user_id = client_info[:requesterUserId]
      user_name = client_info[:fullname]
      meeting_name = client_info[:confname]
      extern_user_id = client_info[:externUserID]
      client_session = client_info[:uniqueClientSession]

      user = {session_token: session_token,
        meeting_id: meeting_id,
        user_id: user_id,
        user_name: user_name,
        meeting_name: meeting_name,
        extern_user_id: extern_user_id,
        client_session: client_session
      }
    end

    def self.proc_user_agent(ua_parser, log)
      ua_raw = log[:userAgent]
      ua_parsed = ua_parser.parse ua_raw
      ua_device = ua_parsed.device
      ua_family = ua_parsed.family
      ua_os = ua_parsed.os
      ua_version = ua_parsed.version

      user_agent = {
        browser: ua_parsed.to_s,
        os: ua_os.to_s,
        raw: ua_raw,
        parsed: ua_parsed.to_h
      }

    end

    def self.pre_proc_log(log)
      client_logger = {
        level_str: log[:levelName],
        level_int: log[:level],
        src: log[:src],
        v: log[:v],
        build: log[:clientBuild],
        url: log[:url],
        count: log[:count]
      }
    end

    def self.parse_log(ua_parser, client_ip, server_timestamp, log)
      user_info = nil
      if log[:userInfo] != nil
        user_info = pre_proc_client_info(log[:userInfo])
      end

      client_logger = pre_proc_log(log)

      log_map = {
        log_code: log[:logCode],
        client_ip: client_ip,
        timestamp: server_timestamp,
        client_timestamp: log[:time],
        client_logger: client_logger,
        msg: log[:msg]
      }

      unless user_info.nil?
        log_map[:session_token] = user_info[:session_token]
        log_map[:meeting_id] = user_info[:meeting_id]
        log_map[:user_id] = user_info[:user_id]
        log_map[:user_name] = user_info[:user_name]
        log_map[:meeting_name] = user_info[:meeting_name]
        log_map[:ext_user_id] = user_info[:extern_user_id]
        log_map[:client_session] = user_info[:client_session]
      end

      unless log[:userAgent].nil?
        user_agent = proc_user_agent(ua_parser, log)
        log_map[:user_agent] = user_agent
      end

      unless log[:extraInfo].nil?
        log_map[:extras] = log[:extraInfo]
        Sherlock::Util.snake_case_keys!(log_map[:extras])
      end

      log_map
    end

    def self.scrub(raw_log)
      line = NginxLogUnescaper.unescape(raw_log)
      Sherlock::Util.scrub_line_to_remove_illegal_chars(line)
    end

    def self.parse_log_data(scrubbed)
      if result = LINE_RE.match(scrubbed)
        log_ip = result[1]
        log_server_date = result[2]
        server_date_iso8601 = DateTime.parse(log_server_date).iso8601(3)
        payload = result[3]

        {
          log_ip: log_ip,
          log_date: server_date_iso8601,
          payload: payload
        }
      else
        nil
      end
    end
  end
end
