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
  def exec_open_operations_file
    operations_are_defined?(required=true) || return
    if COMMAND.options[:edit]
      system('vim', operations_path)
    else
      clear
      notice "=== OPÉRATIONS DÉFINIES ===\n\n"

      colwidth = Operation.column_width
      avant  = " "*(colwidth / 2)
      entete =  (" " * Operation.margin) +
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
  end
end #/ViteFait

class Operation
  class << self
    def window_width
      @window_width ||= `tput cols`.to_i
    end
    def column_width
      @column_width ||= (window_width - (gutter + 2 * margin)) / 2
    end
    def gutter
      @gutter ||= 4
    end
    def margin
      @margin ||= 4
    end
  end #/<< self
  attr_reader :id, :assistant, :voice, :duration
  def initialize data
    data.each { |k, v| instance_variable_set("@#{k}", v) }
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
      puts marg + line_assistant + gutt + line_voice
    end

  end

  def colwidth
    @colwidth ||= self.class.column_width
  end

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
