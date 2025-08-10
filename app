#!/bin/ruby
require "logger"
require "optparse"
require "colorize"
require_relative "helpers/iptables"
require_relative "helpers/requirements"

module Modes
  MODE_BLOCK   = 0
  MODE_UNBLOCK = 1
end

TARGETS_FILE  = "targets"

Options = Struct.new(:mode, :file, :gui)
class Parser
  def self.parse(options)
    # default settings 
    args = Options.new(Modes::MODE_BLOCK, TARGETS_FILE)

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: block.rb [options]"

      opts.on("-mMODE", "--mode=MODE", "block / unblock") do |m|
        case m 
          when "block", "b"
            args.mode = Modes::MODE_BLOCK
          when "unblock", "u"
            args.mode = Modes::MODE_UNBLOCK
          else
            raise "expected mode to be either -mb/--mode=block or -me/--mode=unblock"
        end
      end

      opts.on("-g", "--gui", "launch web gui") do 
        args.gui = true 
      end

      opts.on("-fFILE", "--file=FILE", "targets file path") do |f|
        args.file = f
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(options)
    return args
  end
end

ARGV << "-h" if ARGV.empty?
options = Parser.parse ARGV

if Process.uid != 0
  raise "run as root please!".red
end

raise "this script is intended for android only!".red unless RUBY_PLATFORM.match?(/android/) 

raise "you are missing some binaries!" unless host_meets_requirements?

if options.gui
  require_relative "ui/server"
  Server.run!
else
  raise "targets file was not found!".red unless File.exist?(options.file)

  targets = File.readlines(options.file, chomp: true)
  iptables = IPTables.new()
  iptables.init_rules()

  LOGGER = Logger.new(STDOUT)
  s_time = Time.now
  LOGGER.info("starting in #{options.mode == Modes::MODE_BLOCK ? 'blocking' : 'unblocking'} mode".gray)

  if options.mode == Modes::MODE_BLOCK
    iptables.rules_add(targets)
  else
    iptables.rules_del(targets)
  end

  e_time = ((Time.now - s_time) ).round(2)
  LOGGER.info("finished in #{e_time} seconds".gray)
end
