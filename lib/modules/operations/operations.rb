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
    require_module('operations/define')
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
    if COMMAND.options[:edit]
      unless operations_defined?
        # Quand le fichier des opérations n'est pas encore défini,
        # on en crée un par défaut.
        File.open(operations_path,'wb'){|f| f.write YAML.dump(DEFAULT_DATA_OPERATIONS)}
      end
      system('vim', operations_path)
    else
      operations_defined?(required=true) || return
      clear
      notice "=== OPÉRATIONS DÉFINIES ===\n\n"
      if COMMAND.options[:titre]
        overview_operations_by_titre
        puts <<-EOT
\n\n\n
  Modifier : vitefait -e operations [#{name}]
  Textes   : vitefait operations [#{name}]
  Capture  : vitefait lire-operations [#{name}]
  Extrait  : vitefait lire-operations -r/--range [#{name}]

        EOT
      else
        full_overview_operations
        puts <<-EOT
\n\n\n
  Modifier : vitefait -e operations [#{name}]
  Durée    : vitefait -t operations [#{name}]
  Capture  : vitefait lire-operations [#{name}]
  Extrait  : vitefait lire-operations -r/--range [#{name}]

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

  # Retourne la durée totale (*) du tutoriel estimée d'après
  # la durée des opérations.
  # (*) En fait, c'est la durée hors titre, intro et final
  def duree_totale_estimee
    operations.collect{|o|o.duree_estimee}.inject(:+)
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


  DEFAULT_DATA_OPERATIONS = [
    {
      'id' => 'identifiant_unique',
      'titre' => "Titre",
      'voice' => "Texte qui sera dit par la voix.",
      'action' => "L'opération qu'il faut exécuter",
      'duration' => nil
    }
  ]
end #/ViteFait
