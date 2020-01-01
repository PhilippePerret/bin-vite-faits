# encoding: UTF-8

class Folder
  attr_reader :path
  def initialize pth
    @path = pth
  end

  def mtime
    stats = `find "#{path}" | xargs stat -f "%m" 2> /dev/null`
    Time.at(stats.split("\n").collect{|n|n.to_i}.max)
  end
end
