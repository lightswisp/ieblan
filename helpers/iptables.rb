require "logger"
require "colorize"
require_relative "backup"

IPTABLES_BIN          = "iptables"
IP6TABLES_BIN         = "ip6tables"
IPTABLES_SAVE_BIN     = "iptables-save"
IP6TABLES_SAVE_BIN    = "ip6tables-save"
IPTABLES_RESTORE_BIN  = "iptables-restore"
IP6TABLES_RESTORE_BIN = "ip6tables-restore"

class IPTables 
  def initialize()
    @out_rules4 = nil
    @out_rules6 = nil
    @backup4  = save4()
    @backup6  = save6()
    @version4 = IO.popen([IPTABLES_BIN, "-V"]).read.chomp
    @version6 = IO.popen([IP6TABLES_BIN, "-V"]).read.chomp
    @logger  = Logger.new(STDOUT)

    # we do it on every init
    @backup = Backup.new(3)
    @backup.do_backup(@backup4, @backup6)
  end

  def save4
    return IO.popen([IPTABLES_SAVE_BIN]).read
  end

  def save6
    return IO.popen([IP6TABLES_SAVE_BIN]).read
  end

  def restore4
    file = @backup.latest4
    IO.popen([IPTABLES_RESTORE_BIN, file])
  end

  def restore6
    file = @backup.latest6
    IO.popen([IP6TABLES_RESTORE_BIN, file])
  end

  def version4
    return @version4
  end

  def version6
    return @version6
  end

  def get_rules4
    IO.popen([IPTABLES_BIN, "--line-numbers", "-n", "-L", "OUTPUT"]).read.split("\n")
  end

  def get_rules6
    IO.popen([IP6TABLES_BIN, "--line-numbers", "-n", "-L", "OUTPUT"]).read.split("\n")
  end

  def init_rules
    @out_rules4 = get_rules4()
    @out_rules6 = get_rules6()
  end

  def rule_exist?(uid)
    return rule_exist4?(uid) || rule_exist6?(uid)
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
    pp @out_rules4
    @out_rules4.each do |rule|
      if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
        return rule.scan(/\d+/).first
      end
    end
    return nil
  end

  def find_rule6_line(uid)
    @out_rules6.each do |rule|
      if rule.match?(/owner UID match/) && rule.end_with?(uid.to_s)
        return rule.scan(/\d+/).first
      end
    end
    return nil
  end

  def rules_add(targets)
    rules_add4(targets)
    rules_add6(targets)
  end

  def rules_add4(targets)
    @logger.info("adding for ipv4".gray)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist".red)
        next
      end
      o_uid = File.stat(path).uid
      if rule_exist4?(o_uid)
        @logger.warn("rule for #{path} already exists, skipping..".yellow)
        next
      end
      @logger.info("adding new ipv4 rule for #{target}".green) 
      r = IO.popen([IPTABLES_BIN, "-I", "OUTPUT", "-m", "owner", "--uid-owner", o_uid.to_s, "-j", "DROP"]).read
      @out_rules4 = get_rules4()
    end
  end
    
  def rules_add6(targets)
    @logger.info("adding for ipv6".gray)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist".red)
        next
      end
      o_uid = File.stat(path).uid
      if rule_exist6?(o_uid)
        @logger.warn("rule for #{path} already exists, skipping..".yellow)
        next
      end
      @logger.info("adding new ipv6 rule for #{target}".green) 
      r = IO.popen([IP6TABLES_BIN, "-I", "OUTPUT", "-m", "owner", "--uid-owner", o_uid.to_s, "-j", "DROP"]).read
      @out_rules6 = get_rules6()
    end
  end

  def rules_del(rules)
    rules_del4(rules)
    rules_del6(rules)
  end

  def rules_del4(targets)
    @logger.info("deleting for ipv4".gray)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist".red)
        next
      end
      o_uid = File.stat(path).uid
      puts "o_uid #{o_uid}"
      line_number = find_rule4_line(o_uid) 
      if line_number.nil?
        @logger.warn("skipping rule for #{path}".yellow)
        next
      end
      @logger.info("deleting ipv4 rule for #{target}".green) 
      r = IO.popen([IPTABLES_BIN, "-D", "OUTPUT", line_number]).read
      @out_rules4 = get_rules4()
    end
  end

  def rules_del6(targets)
    @logger.info("deleting for ipv6".gray)
    targets.each do |target|
      path = File.join("/data", "data", target)
      unless File.exist?(path)
        @logger.fatal("path #{path} doesn't exist".red)
        next
      end
      o_uid = File.stat(path).uid
      line_number = find_rule6_line(o_uid) 
      if line_number.nil?
        @logger.warn("skipping rule for #{path}".yellow)
        next
      end
      @logger.info("deleting ipv6 rule for #{target}".green) 
      r = IO.popen([IP6TABLES_BIN, "-D", "OUTPUT", line_number]).read
      @out_rules6 = get_rules6()
    end
  end

end
