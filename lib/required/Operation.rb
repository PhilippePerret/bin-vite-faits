# encoding: UTF-8

class Operation
  class << self
    # Pour retourner la donnée qui devra être enregistrée dans le
    # fichier 'operations.yaml'
    def to_hash(tuto)
      tuto.operations.collect{|o|o.to_hash}
    end

    def window_width
      @window_width ||= IOConsole.width
    end
    def column_width
      @column_width ||= (window_width - (titreWidth + gutter + 2 * margin)) / 2
    end
    def gutter
      @gutter ||= 4
    end
    def margin
      @margin ||= 4
    end
    def titreWidth
      @titreWidth ||= 40 # largeur pour le titre
    end
  end #/<< self

  # ---------------------------------------------------------------------
  #   INSTANCE
  # ---------------------------------------------------------------------

  attr_reader :id, :titre, :assistant, :voice, :duration
  def initialize data
    data.each { |k, v| instance_variable_set("@#{k}", v) }
    calc_reel_assistant_et_secondes_attente # produit assistant_pour_comptage et nombre_secondes_attente_assistant
  end

  def to_hash
    {
      id:id,
      titre:titre,
      assistant:assistant,
      voice:voice,
      duration:duration
    }
  end

  # Pour la régression, pour utiliser encore la forme
  # operations[:property]
  def [] prop
    warn("La méthode crochets ne doit plus être utilisée pour les opérations (utiliser `operation.#{prop}` au lieu de `operation[:#{prop}]`)")
    send(prop.to_sym)
  end

  # Pour l'affichage en ligne avec le titre et les durées
  def line_with_duree(duree_courante)
    des = "#{duree_estimee.to_i} s.".rjust(10)
    fdc = "#{duree_courante.to_i.as_horloge(full = false)} s.".rjust(10)
    "#{(titre||'')[0...50].ljust(50)} | #{des} | #{fdc}"
  end

  def display
    # 47 blanc, 45 violet, 46 bleu
    puts "-"*self.class.window_width
    split_in_two_columns

    #     puts <<-EOT
    #
    # \033[1;33mid: #{id}\033[0m (durée #{duration ? "#{duration} s. " : ''})
    #
    #    #{assistant}
    #
    #   \033[1;47m 🎤 \033[0m #{voice}
    #
    #     EOT
  end

  def split_in_two_columns
    marg = " " * self.class.margin
    gutt = " " * self.class.gutter
    margTitre = ' ' * self.class.titreWidth

    # Toutes les lignes contenant les deux textes
    # en colonnes
    lines_assistant = split_in_column(assistant)
    lines_voice = split_in_column(voice)

    # Nombre maximum de lignes, soit l'assistant soit
    # la voix
    max = [lines_assistant.count, lines_voice.count].max
    # Ligne vierge
    blank_line = " " * colwidth

    max.times do |i|
      line_assistant = (lines_assistant[i]  || blank_line)
      line_voice = (lines_voice[i]          || blank_line)
      if i == 0
        puts marg + f_titre + line_assistant + gutt + line_voice
      else
        puts marg + margTitre + line_assistant + gutt + line_voice
      end
    end

  end

  # Formatage du titre
  def f_titre
    @f_titre ||= begin
      if titre.length > 40
        ft = titre[0..39] + '…'
      else
        ft = titre
      end
      ft.ljust(self.class.titreWidth)
    end
  end

  def colwidth
    @colwidth ||= IOConsole.width
  end



  # Durée estimée de l'opération, en fonction de la longueur
  # de ses textes ou la durée définie explicitement
  def duree_estimee
    @duree_estimee ||= begin
      duree_definie   = duration || 0
      duree_assistant = ((assistant_pour_comptage||'').length * COEF_DICTION  + nombre_secondes_attente_assistant).with_decimal(1)
      duree_voice     = ((voice||'').length * COEF_DICTION).with_decimal(1)
      # On garde comme durée la durée la plus longue
      [duree_definie, duree_assistant, duree_voice].max
    end
  end

  def formated_assistant
    @formated_assistant ||= begin
      ft = assistant.to_s
      ft = ft.gsub(/"/, '\\"')
      # TODO Traiter les ">" (mais il faut certainement le faire dans le
      # le fichier lui-même, avant même de le parser en YAML)
      # Traiter les "Attendre x secondes."
      ft.gsub!(/Attendre ([0-9]+) secondes?\./){
        "[[slnc #{1000 * $1.to_i}]]"
      }

      ft # le texte de l'assistant formaté
    end
  end

  def calc_reel_assistant_et_secondes_attente
    @nombre_secondes_attente_assistant = 0
    @assistant_pour_comptage = assistant.gsub(/ ?Attendre ([0-9]+) secondes?\./){
      nombre_secondes = $1.to_i
      @nombre_secondes_attente_assistant += nombre_secondes
      ''
    }
  end
  def assistant_pour_comptage; @assistant_pour_comptage end
  def nombre_secondes_attente_assistant; @nombre_secondes_attente_assistant end

  # Découper la phrase pour avoir des bonnes découpes en mots, sans que
  # le mot soit coupé comme par défaut ou avec fmt
  def f_voice
    @f_voice ||= begin
      `echo "#{(voice||'--- rien à dire ---').gsub(/"/,'\\"')}" | fmt #{IOConsole.width - 5}`.strip
      # Note : le -5 est là pour tenir compte du fait que pour les voix
      # avant et après par exemple, on ajoute des parenthèses autour dans
      # la console.
    end
  end
  # Découpe un texte en une certaine longueur
  def split_in_column(text)
    words = text.split(' ')
    lines = [] # toutes les lignes produites
    line  = [] # ligne courant
    line_len = 0
    while word = words.shift
      word_len = word.length + 1
      if line_len + word_len > colwidth
        # Il faut mettre ce mot dans la ligne suivante
        # et finir cette ligne
        lines << line.join(' ').ljust(colwidth)
        line  = [] # ligne courant
        line_len = 0
      end
      line << word
      line_len += word_len
    end
    if line.count
      lines << line.join(' ').ljust(colwidth)
    end
    # puts "--- lines =\n#{lines.join("\n")}"
    return lines
  end
end #/Operation
