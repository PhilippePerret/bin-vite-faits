# encoding: UTF-8
class String
  MOIS = {
    1 => {long:'janvier', short:'jan'},
    2 => {long:'février', short:'fév'},
    3 => {long:'mars', short:'mars'},
    4 => {long:'avril', short:'avr'},
    5 => {long:'mai', short:'mai'},
    6 => {long:'juin', short:'juin'},
    7 => {long:'juillet', short:'juil'},
    8 => {long:'aout', short:'aou'},
    9 => {long:'septembre', short:'sept'},
    10  => {long:'octobre', short:'oct'},
    11  => {long:'novembre', short:'nov'},
    12  => {long:'décembre', short:'déc'}
  }

  POUCE = "👍"
  WARNING = "🚫"

  # Convertit le texte en colonnes de largeurs +width+
  # Si options[:indent] est fourni, on ajoute cette indentation
  # à chaque ligne.
  def colonnize width = 50, options = nil # en nombre de caractères
    res = `echo "#{self.gsub(/"/,'\\"')}" | fmt #{width}`
    if options && options[:indent]
      res = options[:indent] + res.gsub!(/\n/, "\n#{options[:indent]}")
    end
    return res
  end
  # Quand le string est une horloge, retourne le nombre de secondes
  def h2s
    pms = self.split(':').reverse
    pms[0].to_i + (pms[1]||0) * 60 + (pms[2]||0) * 3660
  end

  def self.levenshtein_beween(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m+1) {Array.new(n+1)}

    (0..m).each {|i| d[i][0] = i}
    (0..n).each {|j| d[0][j] = j}
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                    d[i-1][j-1]       # no operation required
                  else
                    [ d[i-1][j]+1,    # deletion
                      d[i][j-1]+1,    # insertion
                      d[i-1][j-1]+1,  # substitution
                    ].min
                  end
      end
    end
    d[m][n]
  end
end
