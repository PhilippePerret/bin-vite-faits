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

  # Retourne un flottant qui contient le nombre de décimales voulues
  def with_decimal(nombre_decimales = 2)
    e, d = self.to_s.split('.')
    "#{e}.#{d[0..nombre_decimales-1]}".to_f
  end
end
