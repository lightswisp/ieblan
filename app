#!/bin/ruby
require "logger"
require "optparse"
require "colorize"
require_relative "helpers/backup"
require_relative "helpers/iptables"
require_relative "helpers/requirements"

module Modes
  MODE_BLOCK   = 0
  MODE_UNBLOCK = 1
end

TARGETS_FILE  = "targets"

Options = Struct.new(
  :mode, 
  :file, 
  :gui,
  :backup_dir,
  :backup_limit,
  :restore_num
)
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

      opts.on("-lLIMIT", "--backup-limit=LIMIT", "limit of backups") do |l|
        args.backup_limit = l
        raise "todo"
      end

      opts.on("--backup-dir=DIR", "specific backups dir") do |d|
        args.backup_dir = d
        raise "todo"
      end

      opts.on("--backup-list", "list available backups") do 
        if args.backup_dir
          b = Backup.new(args.backup_dir).list4
        else
          b = Backup.new.list4
        end
        unless b.size.zero?
          puts "available backups:"
          b.each_with_index do |b, i|
            puts "\t [ #{i.to_s.yellow} ] #{b.gray}"
          end
        else
          puts "no backups available"
        end
        exit
      end

      opts.on("--backup-restore=NUM", "restore the backup") do |n|
        args.restore_num = n.to_i
        raise "todo"
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
  Thread.new {
    IO.popen(["xdg-open", "http://127.0.0.1:4567"])
  }
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
