#!/usr/bin/ruby

# Extracts data from html5 log.  Currently parses
#  - All messages with an error log level.

require 'json'
require 'user_agent_parser'
require 'optparse'
require './lib/sherlock'

def print_pretty_json(options, data)
  if options[:no_ua] != nil
    data.delete(:user_agent)
    data.delete(:client_logger)
  end

  puts JSON.pretty_generate(data) + "\n"
end

def print_table_for_meeting(data)
  log_str = "%s %-14.14s %-50.50s %-20.20s %-100s" % [
    data[:timestamp],
    data[:user_id],
    data[:log_code],
    data[:user_name][0..20],
    data[:msg][0..100]
  ]
  puts log_str
end

def print_table_for_user(data)
  log_str = "%s %-30.30s %-20.20s %-100s" % [
    data[:timestamp],
    data[:log_code],
    data[:user_name][0..20],
    data[:msg][0..100]
  ]
  puts log_str
end

def print_table_for_all(data)
  log_str = "%s %-54.54s %-14.14s %-30.30s %-30.30s %-100s" % [
    data[:timestamp].nil? ? 'null' : data[:timestamp],
    data[:meeting_id].nil? ? 'null' : data[:meeting_id],
    data[:user_id].nil? ? 'null' : data[:user_id],
    data[:log_code][0..30],
    data[:user_name].nil? ? 'null' : data[:user_name][0..30],
    data[:msg][0..100]
  ]
  puts log_str
end

def print_meeting_and_user(options, data)
  if options[:json_out] != nil
    print_pretty_json(options, data)
  else
    print_table_for_user(data)
  end
end

def match_meeting_and_user?(options, data)
  options[:meeting_id] == data[:meeting_id] &&
    options[:user_id] == data[:user_id]
end

def print_meeting(options, data)
  if options[:json_out] != nil
    print_pretty_json(options, data)
  else
    print_table_for_meeting(data)
  end
end

def meeting_option?(options)
  options[:meeting_id] != nil
end

def match_meeting?(options, data)
  options[:meeting_id] == data[:meeting_id]
end

def print_all(options, data)
  if options[:json_out] != nil
    print_pretty_json(options, data)
  else
    print_table_for_all(data)
  end
end

def meeting_and_user_option?(options)
  options[:meeting_id] != nil && options[:user_id] != nil
end

def what_to_print(options, data)
  if meeting_and_user_option?(options)
    if match_meeting_and_user?(options, data)
      print_meeting_and_user(options, data)
    end
  elsif meeting_option?(options)
    if match_meeting?(options, data)
      print_meeting(options, data)
    end
  else
    print_all(options, data)
  end
end

options = { }
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: #{$0} [OPTIONS]"
  opt.separator ""
  opt.separator "OPTIONS"

  opt.on("-m", "--meeting MEETING", "meeting to display.") do |meeting_id|
    options[:meeting_id] = meeting_id
  end

  opt.on("-u", "--user USER", "user to display") do |user_id|
    options[:user_id] = user_id
  end

  opt.on("-j", "pretty json") do |json_out|
    options[:json_out] = json_out
  end

  opt.on("-n", "No user agent and logger when printing as json") do |no_ua|
    options[:no_ua] = no_ua
  end
end
opt_parser.parse!

ua_parser = UserAgentParser::Parser.new

ARGF.each do |log_line|
  begin
    scrubbed = Html5Client::Parser.scrub(log_line)
    log_data = Html5Client::Parser.parse_log_data(scrubbed)
    unless log_data.nil?
      begin
        data = JSON.parse(log_data[:payload], :symbolize_names => true)
        data.each do |log|
          log_map = Html5Client::Parser.parse_log(ua_parser, log_data[:log_ip], log_data[:log_date], log)
          unless log_map.nil?
            what_to_print(options, log_map)
          end
        end
      rescue StandardError => msg
        #puts msg
      end
    end
  rescue StandardError => msg
    #puts msg
  end
end
