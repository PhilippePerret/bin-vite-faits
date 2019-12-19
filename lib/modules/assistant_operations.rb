# encoding: UTF-8
=begin

  Ce module permet d'assistant à tout ce qui concerne les opérations
  À savoir :
    - la création du fichier opération lui-même
    - la lecture des opérations à exécuter
    - l'assistance de l'enregistrement de la voix

=end
class ViteFait

  # Assistant pour la création du fichier opérations
  def assistant_creation_file
    clear
    notice "Nous allons créer ensemble le fichier des opérations"

    operations = nil

    if file_operations_exists?
      case prompt("Le fichier des opérations existe déjà. Que dois-je faire :\n\n\tA : le détruire pour recommencer\n\tB : le poursuivre\n\tC : Renoncer et l'éditer avec Vim\n\nTon choix").downcase
      when 'a'
        # Détruire le fichier
        File.unlink(operations_path)
      when 'b'
        # Poursuivre le fichier
        operations = YAML.load_file(operations_path)
      when 'c'
        # Éditer le fichier avec Vim
        return open_operations_file
      else
        error "Je ne comprends pas ce choix. Je préfère renoncer."
        return
      end
    else

    end

    operations = get_all_operations_voulues(operations)

    # TODO Affichage des opérations

    yesNo("Dois-je procéder à la fabrication du fichier des opérations ?") || return

    # Créer le dossier s'il n'existe pas
    `mkdir -p "#{operations_folder}"`

    File.open(operations_path,'wb'){|f| f.write YAML.dump(operations)}

    notice "Fichier des opérations enregistré avec succès."
    puts "Tu peux jouer la commande suivante pour que l'assistant te lise les opérations à exécuter :\n\n\tvite-faits assistant #{name} pour=capture\n\n"
    puts "Tu peux jouer la commande suivante pour afficher le texte à dire par la voix finale :\n\n\tvite-faits assistant #{name} pour=voice\n\n"
    puts "\n\n"

  rescue NotAnError => e
    error "\n\nAssistance interrompue."
  end

  def get_all_operations_voulues(operations = nil)
    operations ||= []
    operations_ids = {}
    operations.each { |op| operations_ids.merge!( op[:id] => true ) }

    while true
      # identifiant de l'opération
      begin
        operation_id = prompt("Identifiant la nouvelle opération (rien pour arrêter)")
        if operation_id.nil? || operation_id == 'q'
          return operations
        end
      end while operation_id_invalid?(operation_id, operations_ids)
      raise NotAnError.new() if operation_id == 'q'

      # Manipulation à opérer
      begin
        operation_assistant = prompt("Message à dire par l'assistant ('q' pour interrompre)")
      end while operation_assistant.nil?
      raise NotAnError.new() if operation_assistant == 'q'

      # Texte de la voix finale
      begin
        operation_voice = prompt("Texte à dire par la voix finale ('q' pour interrompre)")
      end while operation_voice.nil?
      raise NotAnError.new() if operation_voice == 'q'

      operation_duration = prompt("Durée forcée en seconde, ou vide ('q' pour interrompre)")
      raise NotAnError.new() if operation_duration == 'q'
      operation_duration.nil? || operation_duration = operation_duration.to_i

      operations << {
        id:         operation_id,
        assistant:  operation_assistant,
        voice:      operation_voice,
        duration:   operation_duration
      }

      # Pour checker l'unicité des identifiants d'opération
      operations_ids.merge!(operation_id => true)

    end
  end


  # Assistant pour la réalisation des opérations, en les lisant
  def exec_lecture_operations
    file_operations_exists?(true) || return
    operations = YAML.load_file(operations_path)
    clear
    notice "Je vais lire les opérations à exécuter"
    puts "Tu peux interrompre à tout moment avec CTRL-C."
    yesNo("Es-tu prêt ? (j'attendrai 5 secondes avant de commencer)") || return
    decompte("Démarrage dans %{nombre_secondes}", 5)
    dire("C'est parti ! Mets en route la capture !")
    operations.each do |operation|
      if operation[:duration]
        end_sleep_time = Time.now.to_i + operation[:duration]
      end
      `say -v Thomas -r 140 "#{operation[:assistant]}"`
      if operation[:duration]
        sleep_reste = end_sleep_time - Time.now.to_i
      else
        sleep_reste = 1
      end
      sleep sleep_reste
    end

    unless COMMAND.options[:silence]
      dire "C'est fini ! Tu peux revenir dans le terminal"
      puts "\n\nPense bien à déplacer la capture dans le dossier du tutoriel (je peux ouvrir les deux)"
      notice "Tu peux enregistrer la voix finale avec :\n\n\tvite-faits assistant #{name} pour=voice\n"
      notice "Tu peux demander l'assemblage avec :\n\n\tvite-faits assemble #{name}\n"
      if yesNo("Dois-je ouvrir le dossier des captures ?")
        ViteFait.open_folder_captures
      end
      if yesNo("Dois-je ouvrir le dossier du tutoriel ?")
        open_in_finder(:chantier)
      end
      notice "Bonne continuation !\n\n"
    end
  end

  # Assistant pour l'enregistrement de la voix finale
  def exec_assistant_voix_finale
    file_operations_exists?(required = true) || return
    operations = YAML.load_file(operations_path)
    puts operations.inspect
  end


  # Retourne true si l'identifiant d'opération +op_id+ est valide
  def operation_id_invalid?(op_id, operations_ids)
    op_id.nil? && raise("Il faut définir l'identifiant unique de l'opération.")
    operations_ids.key?(op_id) && raise("Cet identifiant est déjà utilisé par une opération.")
    return false
  rescue Exception => e
    error(e.message)
    error("Mettre l'id à 'q' pour renoncer.")
    return true
  end
end #/ViteFait
