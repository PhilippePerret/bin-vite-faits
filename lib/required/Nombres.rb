# encoding: UTF-8
class Integer
  def as_horloge
    hrs = self / 3600
    reste = self % 3600
    mns = reste / 60
    scs = reste % 60
    "#{hrs.to_s.rjust(2,'0')}:#{mns.to_s.rjust(2,'0')}:#{scs.to_s.rjust(2,'0')}"
  end
end

class Float

end
