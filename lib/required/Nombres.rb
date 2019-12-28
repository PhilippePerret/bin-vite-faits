# encoding: UTF-8
class Integer
  def as_horloge(full = true)
    hrs = self / 3600
    reste = self % 3600
    mns = reste / 60
    scs = reste % 60
    if full
      "#{hrs.to_s.rjust(2,'0')}:#{mns.to_s.rjust(2,'0')}:#{scs.to_s.rjust(2,'0')}"
    else
      hrs_s = hrs > 0 ? "#{hrs}:" : ''
      mns_s = hrs > 0 ? mns.to_s.rjust(2,'0') : mns
      scs_s = scs.to_s.rjust(2,'0')
      "#{hrs_s}#{mns_s}:#{scs_s}"
    end
  end
end

class Float

  # Retourne un flottant qui contient le nombre de décimales voulues
  def with_decimal(nombre_decimales = 2)
    # e, d = self.to_s.split('.')
    self.with_decimal_str(nombre_decimales).to_f
  end
  def with_decimal_str(nombre_decimales = 2)
    e, d = self.to_s.split('.')
    "#{e}.#{d[0..nombre_decimales-1]}"
  end
end
