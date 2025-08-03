#!/bin/ruby
require "logger"
require "optparse"

module Modes
  MODE_BLOCK   = 0
  MODE_UNBLOCK = 1
end

TARGETS_FILE  = "targets"

Options = Struct.new(:mode, :file)
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
$options = Parser.parse ARGV

IPTABLES_BIN  = "iptables"
IP6TABLES_BIN = "ip6tables"

if Process.uid != 0
  raise "run as root please!"
end

raise "this script is intended for android only!" unless RUBY_PLATFORM.match?(/android/) 
raise "targets file was not found!"               unless File.exist?($options.file)

def get_rules4
  IO.popen([IPTABLES_BIN, "--line-numbers", "-n", "-L", "OUTPUT"]).read.split("\n")
end

def get_rules6
  IO.popen([IP6TABLES_BIN, "--line-numbers", "-n", "-L", "OUTPUT"]).read.split("\n")
end

$out_rules4 = get_rules4()
$out_rules6 = get_rules6()

def rule_exist4?(uid)
  $out_rules4.each do |rule|
    if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
      return true
    end
  end
  return false
end

def rule_exist6?(uid)
  $out_rules6.each do |rule|
    if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
      return true
    end
  end
  return false
end

def find_rule4_line(uid)
  $out_rules4.each do |rule|
    if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
      return rule[0]
    end
  end
  return nil
end

def find_rule6_line(uid)
  $out_rules6.each do |rule|
    if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
      return rule[0]
    end
  end
  return nil
end

def rules_add4
  LOGGER.info("adding for ipv4")
  targets = File.readlines($options.file, chomp: true)
  targets.each do |target|
    path = File.join("/data", "data", target)
    unless File.exist?(path)
      LOGGER.fatal("path #{path} doesn't exist")
      next
    end
    o_uid = File.stat(path).uid
    if rule_exist4?(o_uid)
      LOGGER.warn("rule for #{o_uid} already exists, skipping..")
      next
    end
    LOGGER.info("adding new ipv4 rule for #{target}") 
    r = IO.popen([IPTABLES_BIN, "-A", "OUTPUT", "-m", "owner", "--uid-owner", o_uid.to_s, "-j", "DROP"]).read
  end
end
  
def rules_add6
  LOGGER.info("adding for ipv6")
  targets = File.readlines($options.file, chomp: true)
  targets.each do |target|
    path = File.join("/data", "data", target)
    unless File.exist?(path)
      LOGGER.fatal("path #{path} doesn't exist")
      next
    end
    o_uid = File.stat(path).uid
    if rule_exist6?(o_uid)
      LOGGER.warn("rule for #{o_uid} already exists, skipping..")
      next
    end
    LOGGER.info("adding new ipv6 rule for #{target}") 
    r = IO.popen([IP6TABLES_BIN, "-A", "OUTPUT", "-m", "owner", "--uid-owner", o_uid.to_s, "-j", "DROP"]).read
  end
end

def rules_del4
  LOGGER.info("deleting for ipv4")
  targets = File.readlines($options.file, chomp: true)
  targets.each do |target|
    path = File.join("/data", "data", target)
    unless File.exist?(path)
      LOGGER.fatal("path #{path} doesn't exist")
      next
    end
    o_uid = File.stat(path).uid
    line_number = find_rule4_line(o_uid) 
    if line_number.nil?
      LOGGER.warn("skipping rule for #{path}")
      next
    end
    LOGGER.info("deleting ipv4 rule for #{target}") 
    r = IO.popen([IPTABLES_BIN, "-D", "OUTPUT", line_number]).read
    $out_rules4 = get_rules4()
  end
end

def rules_del6
  LOGGER.info("deleting for ipv6")
  targets = File.readlines($options.file, chomp: true)
  targets.each do |target|
    path = File.join("/data", "data", target)
    unless File.exist?(path)
      LOGGER.fatal("path #{path} doesn't exist")
      next
    end
    o_uid = File.stat(path).uid
    line_number = find_rule6_line(o_uid) 
    if line_number.nil?
      LOGGER.warn("skipping rule for #{path}")
      next
    end
    LOGGER.info("deleting ipv6 rule for #{target}") 
    r = IO.popen([IP6TABLES_BIN, "-D", "OUTPUT", line_number]).read
    $out_rules6 = get_rules6()
  end
end

LOGGER = Logger.new(STDOUT)
s_time = Time.now
LOGGER.info("starting in #{$options.mode == Modes::MODE_BLOCK ? 'blocking' : 'unblocking'} mode")

if $options.mode == Modes::MODE_BLOCK
  rules_add4()
  rules_add6()
else
  rules_del4()
  rules_del6()
end

e_time = ((Time.now - s_time) ).round(2)
LOGGER.info("finished in #{e_time} seconds")
