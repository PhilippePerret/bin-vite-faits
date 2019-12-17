def error msg, options = {}
  puts "\033[1;31m#{msg}\033[0m"
  return false
end
def notice msg, options = {}
  puts "\033[1;32m#{msg}\033[0m"
end

def write_green msg
  puts "\033[1;32m#{msg}\033[0m"
end
def write_purple msg
  puts "\033[1;34m#{msg}\033[0m"
end
def write_yellow msg
  puts "\033[1;33m#{msg}\033[0m"
end
def write_fushia msg
  puts "\033[1;35m#{msg}\033[0m"
end
def write_cyan msg
  puts "\033[1;36m#{msg}\033[0m"
end
