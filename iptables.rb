require "logger"

IPTABLES_BIN  = "iptables"
IP6TABLES_BIN = "ip6tables"

class IPTables 
  def initialize(options)
    @out_rules4 = nil
    @out_rules6 = nil
    @options = options
    @logger  = Logger.new(STDOUT)
  end

  def get_rules4
    IO.popen([IPTABLES_BIN, "--line-numbers", "-n", "-L", "OUTPUT"]).read.split("\n")
  end

  def get_rules6
    IO.popen([IP6TABLES_BIN, "--line-numbers", "-n", "-L", "OUTPUT"]).read.split("\n")
  end

  def update_rules
    @out_rules4 = get_rules4()
    @out_rules6 = get_rules6()
  end

  def rule_exist4?(uid)
    @out_rules4.each do |rule|
      if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
        return true
      end
    end
    return false
  end

  def rule_exist6?(uid)
    @out_rules6.each do |rule|
      if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
        return true
      end
    end
    return false
  end

  def find_rule4_line(uid)
    @out_rules4.each do |rule|
      if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
        return rule[0]
      end
    end
    return nil
  end

  def find_rule6_line(uid)
    @out_rules6.each do |rule|
      if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
        return rule[0]
      end
    end
    return nil
  end

  def rules_add
    rules_add4()
    rules_add6()
  end

  def rules_add4
    @logger.info("adding for ipv4")
    targets = File.readlines(@options.file, chomp: true)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist")
        next
      end
      o_uid = File.stat(path).uid
      if rule_exist4?(o_uid)
        @logger.warn("rule for #{o_uid} already exists, skipping..")
        next
      end
      @logger.info("adding new ipv4 rule for #{target}") 
      r = IO.popen([IPTABLES_BIN, "-A", "OUTPUT", "-m", "owner", "--uid-owner", o_uid.to_s, "-j", "DROP"]).read
    end
  end
    
  def rules_add6
    @logger.info("adding for ipv6")
    targets = File.readlines(@options.file, chomp: true)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist")
        next
      end
      o_uid = File.stat(path).uid
      if rule_exist6?(o_uid)
        @logger.warn("rule for #{o_uid} already exists, skipping..")
        next
      end
      @logger.info("adding new ipv6 rule for #{target}") 
      r = IO.popen([IP6TABLES_BIN, "-A", "OUTPUT", "-m", "owner", "--uid-owner", o_uid.to_s, "-j", "DROP"]).read
    end
  end

  def rules_del
    rules_del4()
    rules_del6()
  end

  def rules_del4
    @logger.info("deleting for ipv4")
    targets = File.readlines(@options.file, chomp: true)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist")
        next
      end
      o_uid = File.stat(path).uid
      line_number = find_rule4_line(o_uid) 
      if line_number.nil?
        @logger.warn("skipping rule for #{path}")
        next
      end
      @logger.info("deleting ipv4 rule for #{target}") 
      r = IO.popen([IPTABLES_BIN, "-D", "OUTPUT", line_number]).read
      @out_rules4 = get_rules4()
    end
  end

  def rules_del6
    @logger.info("deleting for ipv6")
    targets = File.readlines(@options.file, chomp: true)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist")
        next
      end
      o_uid = File.stat(path).uid
      line_number = find_rule6_line(o_uid) 
      if line_number.nil?
        @logger.warn("skipping rule for #{path}")
        next
      end
      @logger.info("deleting ipv6 rule for #{target}") 
      r = IO.popen([IP6TABLES_BIN, "-D", "OUTPUT", line_number]).read
      @out_rules6 = get_rules6()
    end
  end

end
