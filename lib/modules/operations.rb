# encoding: UTF-8
=begin

  Ce module permet d'assistant à tout ce qui concerne les opérations
  À savoir :
    - la création du fichier opération lui-même
    - la lecture des opérations à exécuter
    - l'assistance de l'enregistrement de la voix

=end
class ViteFait
  def assistant_creation_file
    require_relative 'assistant/define_operations'
    exec
  rescue NotAnError => e
    e.puts_error_if_message
    return false
  end

  # Ouvrir le fichier opérations, en lecture ou en édition
  # Avec l'option '-e/--edit', le fichier est ouvert en édition dans Vim
  # Avec l'option '-t/--titre', on affiche une vision simple avec seulement
  # les titres et les durées approximatives des opérations.
  def exec_open_operations_file
    operations_are_defined?(required=true) || return
    if COMMAND.options[:edit]
      system('vim', operations_path)
    else
      clear
      notice "=== OPÉRATIONS DÉFINIES ===\n\n"
      if COMMAND.options[:titre]
        overview_operations_by_titre
        puts <<-EOT
\n\n\n
  Modifier : vite-faits -e open-operations [#{name}]
  Textes   : vite-faits open-operations [#{name}]
  Capture  : vite-faits lire_operations [#{name}]

        EOT
      else
        full_overview_operations
        puts <<-EOT
\n\n\n
  Modifier : vite-faits -e open-operations [#{name}]
  Durée    : vite-faits -t open-operations [#{name}]
  Capture  : vite-faits lire_operations [#{name}]

        EOT
      end
    end
  end

  # Aperçu par titre, avec la durée de chaque opération
  def overview_operations_by_titre
    puts "(aperçu par titre et durée)\n\n"
    duree_totale = 0
    get_operations.each do |dope|
      operation = Operation.new(dope)
      puts "    " + operation.line_with_duree(duree_totale)
      duree_totale += operation.duree_estimee
    end
  end

  def full_overview_operations

    colwidth = Operation.column_width
    avant  = " "*(colwidth / 2)
    titreLen = Operation.titreWidth

    entete =  (" " * Operation.margin) +
              ( "   Titre".ljust(titreLen)) +
              (avant+'XXXX').ljust(colwidth).sub(/XXXX/,"\033[1;47m 🎧 \033[0m") +
              (" " * Operation.gutter) +
              (avant+'XXXX').ljust(colwidth).sub(/XXXX/,"\033[1;47m 🎤 \033[0m")

    puts entete
    get_operations.each do |dope|
      ope = Operation.new(dope)
      ope.display
    end
    puts "\n\n(pour éditer les opérations : vite-faits operations #{name} -e/--edit)"
  end


end #/ViteFait

class Operation
  class << self
    def window_width
      @window_width ||= `tput cols`.to_i
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
  end

  # Pour l'affichage en ligne avec le titre et les durées
  def line_with_duree(duree_courante)
    des = "#{duree_estimee.to_i} s.".rjust(10)
    fdc = "#{duree_courante} s.".rjust(10)
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
    @colwidth ||= self.class.column_width
  end


  # Durée estimée de l'opération, en fonction de la longueur
  # de ses textes ou la durée définie explicitement
  def duree_estimee
    @duree_estimee ||= begin
      duree_definie   = duration || 0
      duree_assistant = (assistant.length * COEF_DICTION).with_decimal(1)
      duree_voice     = (voice.length * COEF_DICTION).with_decimal(1)
      # On garde comme durée la durée la plus longue
      [duree_definie, duree_assistant, duree_voice].max
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
end
