require "mkmf"

REQUIRED_BINARIES = [
  "iptables",
  "ip6tables",
  "cmd",
  "xdg-open"
]

def host_meets_requirements?
  REQUIRED_BINARIES.each do |bin|
    return false if find_executable(bin).nil?  
  end
  return true
end
