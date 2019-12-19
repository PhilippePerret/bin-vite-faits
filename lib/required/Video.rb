# encoding: UTF-8
class Video
  def self.dureeOf(path)
    duration = `ffmpeg -i "#{path}" 2>&1 | grep "Duration"`
    duration = duration.scan(/([0-9]{1,2}\:[0-9]{1,2}\:[0-9]{1,2}\.[0-9]{1,4})/)
    duration = duration[0][0]
    # puts "Durée : '#{duration}'"
    d = duration.split(/[:\.]/).collect{|h| h.to_i}
    return (((d[0] * 3600 + d[1] * 60 + d[2]) * 100) + d[3]).to_f / 100
    # puts "Duration : #{duration}"
  end
end
