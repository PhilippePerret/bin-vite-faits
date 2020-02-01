# encoding: UTF-8
class String

  # Prend un string 'JJ MM AAAA' et retourne la date correspondante
  def ddmmyyyy2date
    j,m,a = self.split(' ')
    return Date.parse("#{a}/#{m}/#{j}")
  rescue Exception => e
    error "La date de publication (#{date}) est mal formatée (attendu : 'JJ MM AAAA') : #{e.message}."
    return self
  end
  alias :jjmmaaaa2date :ddmmyyyy2date
end
