require "mkmf"

REQUIRED_BINARIES = [
  "iptables",
  "ip6tables",
  "cmd",
  "xdg-open",
  "iptables-save",
  "ip6tables-save",
  "iptables-restore",
  "ip6tables-restore"
]

def host_meets_requirements?
  REQUIRED_BINARIES.each do |bin|
    return false if find_executable(bin).nil?  
  end
  return true
end
