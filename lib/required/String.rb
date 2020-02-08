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

  # Le texte en bleu gras pour le terminal
  def bleu_gras
    "\033[1;96m#{self}\033[0m"
  end
  def bleu_gras_html
    "<span style=\"color:blue;font-weight:bold;\">#{self}</span>"
  end
  # Le texte en bleu gras pour le terminal
  def bleu
    "\033[0;96m#{self}\033[0m"
    # 96=bleu clair, 93 = jaune, 94/95=mauve, 92=vert
  end
  def bleu_html
    "<span style=\"color:blue;\">#{self}</span>"
  end
  def mauve
    "\033[1;94m#{self}\033[0m"
  end
  def mauve_html
    "<span style=\"color:purple;\">#{self}</span>"
  end

  def fond1
    "\033[38;5;8;48;5;45m#{self}\033[0m"
  end
  def fond1_html
    "<span style=\"background-color:red;color:white;\">#{self}</span>"
  end
  def fond2
    "\033[38;5;8;48;5;40m#{self}\033[0m"
  end
  def fond2_html
    "<span style=\"background-color:green;color:white;\">#{self}</span>"
  end
  def fond3
    "\033[38;5;0;48;5;183m#{self}\033[0m"
  end
  def fond3_html
    "<span style=\"background-color:blue;color:white;\">#{self}</span>"
  end
  def fond4
    "\033[38;5;15;48;5;197m#{self}\033[0m"
  end
  def fond4_html
    "<span style=\"background-color:purple;color:white;\">#{self}</span>"
  end
  def fond5
    "\033[38;5;15;48;5;172m#{self}\033[0m"
  end
  def fond5_html
    "<span style=\"background-color:orange;color:white;\">#{self}</span>"
  end

  def jaune
    "\033[0;93m#{self}\033[0m"
  end
  alias :yellow :jaune
  def jaune_html
    "<span style=\"color:yellow;\">#{self}</span>"
  end

  def orange_html
    "<span style=\"color:orange;\">#{self}</span>"
  end

  def vert
    "\033[0;92m#{self}\033[0m"
  end
  def vert_html
    "<span style=\"color:green;\">#{self}</span>"
  end

  # Le texte en rouge gras pour le terminal
  def rouge_gras
    "\033[1;31m#{self}\033[0m"
  end
  def rouge_gras_html
    "<span style=\"color:red;font-weight:bold;\">#{self}</span>"
  end

  # Le texte en rouge gras pour le terminal
  def rouge
    "\033[0;91m#{self}\033[0m"
  end
  def rouge_html
    "<span style=\"color:red;\">#{self}</span>"
  end

  def rouge_clair
    "\033[0;35m#{self}\033[0m"
  end
  def rouge_clair_html
    "<span style=\"color:#FF8888;\">#{self}</span>"
  end

  def gris
    "\033[0;90m#{self}\033[0m"
  end
  def gris_html
    "<span style=\"color:grey;\">#{self}</span>"
  end

  def gras
    "\033[1;38m#{self}\033[0m"
  end
  def purple
    "\033[1;34m#{self}\033[0m"
  end
  def yellow
    "\033[1;33m#{self}\033[0m"
  end
  def fushia
    "\033[1;35m#{self}\033[0m"
  end
  def cyan
    "\033[1;36m#{self}\033[0m"
  end
  def grey
    "\033[1;90m#{self}\033[0m"
  end

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
