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
      # `open -a MacVim "#{operations_path}"`
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
    operations.each do |operation|
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
    operations.each { |ope| ope.display }
    puts "\n\n(pour éditer les opérations : vite-faits operations #{name} -e/--edit)"
  end


end #/ViteFait
