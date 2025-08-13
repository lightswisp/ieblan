require "logger"
require "colorize"

class Backup
  def initialize(path="backups", limit=3)
    @path  = path
    @limit = limit
    @v4_path = File.join(@path, "v4")
    @v6_path = File.join(@path, "v6")
    @logger  = Logger.new(STDOUT)

    # create dirs
    FileUtils.makedirs(@v4_path) unless Dir.exist?(@v4_path)
    FileUtils.makedirs(@v6_path) unless Dir.exist?(@v6_path)
  end

  def list4
    return Dir.children(@v4_path).sort_by{|c| File.stat(File.join(@v4_path, c)).ctime}
  end

  def list6
    return Dir.children(@v6_path).sort_by{|c| File.stat(File.join(@v6_path, c)).ctime}
  end

  def do_backup(backup4_contents, backup6_contents)

    do_backup4(backup4_contents)
    do_backup6(backup6_contents)

  end

  def do_backup4(backup4_contents)
    files = Dir.children(@v4_path)
    if(files.size >= @limit)
      # remove the oldest backup 
      sorted_files = files.sort_by{|c| File.stat(File.join(@v4_path, c)).ctime} 
      File.delete(File.join(@v4_path, sorted_files.first))
      @logger.warn("the oldest backup for ipv4 '#{sorted_files.first}' has been deleted".yellow)
    end

    # create new backup
    time = Time.now.strftime("%Y%m%d%H%M%S")
    fname = "iptables_backup_#{time}"
    @logger.info("creating new backup for ipv4 '#{fname}'".green)
    File.write(File.join(@v4_path, fname), backup4_contents)
  end

  def do_backup6(backup6_contents)
    files = Dir.children(@v6_path)
    if(files.size >= @limit)
      # remove the oldest backup 
      sorted_files = files.sort_by{|c| File.stat(File.join(@v6_path, c)).ctime} 
      File.delete(File.join(@v6_path, sorted_files.first))
      @logger.warn("the oldest backup for ipv6 '#{sorted_files.first}' has been deleted".yellow)
    end

    # create new backup
    time = Time.now.strftime("%Y%m%d%H%M%S")
    fname = "iptables_backup_#{time}"
    @logger.info("creating new backup for ipv6 '#{fname}'".green)
    File.write(File.join(@v6_path, fname), backup6_contents)
  end

  def latest4
    files = Dir.children(@v4_path)
    sorted_files = files.sort_by{|c| File.stat(File.join(@v4_path, c)).ctime} 
    return File.join(@v4_path, sorted_files.last)
  end

  def latest6
    files = Dir.children(@v6_path)
    sorted_files = files.sort_by{|c| File.stat(File.join(@v6_path, c)).ctime} 
    return File.join(@v6_path, sorted_files.last)
  end

end
