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
      case prompt("Le fichier des opérations existe déjà. Que dois-je faire :\n\n\tA : le détruire pour recommencer\n\tB : le poursuivre\n\tC : l'éditer avec Vim\n\tD : renoncer\n\nTon choix").downcase
      when 'a'
        # Détruire le fichier
        File.unlink(operations_path)
      when 'b'
        # Poursuivre le fichier
        operations = get_operations
      when 'c'
        # Éditer le fichier avec Vim
        return open_operations_file
      when 'd'
        return
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

  def get_operations
    YAML.load_file(operations_path).to_sym
  end

  # Assistant pour la réalisation des opérations, en les lisant
  def exec_lecture_operations
    file_operations_exists?(true) || return
    operations = get_operations
    clear
    puts "\n\n"
    notice "Je vais lire les opérations à exécuter"
    puts <<-EOT
Nous allons :
  - activer Scrivener
  - masquer les autres application (CMD+ALT+H)
  - régler les paramètres de la capture

Ne panique pas, je vais t'accompagner au cours de toutes ces opérations.

À tout moment, si ça ne se passe pas bien, tu peux interrompre
la capture à l'aide de CTRL-C.

    EOT

    `open -a Terminal`
    yesNo("Es-tu prêt à me suivre ?…") || return
    dire("Active Scrivener et masque les autres applications")
    sleep 3
    dire("Règle la capture (plein écran, du son, démarrage immédiat)")
    sleep 4
    dire("Démarrage dans 10 secondes")
    decompte("Démarrage dans %{nombre_secondes}", 4)
    dire("Démarrage dans 5 secondes")
    decompte("Démarrage dans %{nombre_secondes}", 4, 'Audrey')
    dire("C'est parti ! Mets en route la capture !")
    operations.each do |operation|
      if operation[:duration]
        end_sleep_time = Time.now.to_i + operation[:duration]
      end
      `say -v Thomas -r 140 "#{operation[:assistant]}"`
      if operation[:duration]
        sleep_reste = end_sleep_time - Time.now.to_i
        sleep_reste < 0 && sleep_reste = 0
      else
        sleep_reste = 1
      end
      sleep sleep_reste
    end

    sleep 3

    unless COMMAND.options[:silence]
      dire "C'est fini. Tu peux arrêter la capture et revenir dans le terminal"
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

    return true # pour poursuivre
  end

  # Assistant pour l'enregistrement de la voix finale
  # La méthode passe en revue chaque opération en écrivant le texte à lire,
  # en maintenant le rythme adéquat
=begin
RÉFLEXION
  Dans l'idéal, il faudra avoir la vidéo, et le texte. Ce serai possible en
  double écran partagé, avec d'un côté la capture des opérations et de l'autre
  la fenêtre de terminal.
=end
  def exec_assistant_voix_finale
    file_operations_exists?(required = true) || return

    # Dans le cas où un fichier voix existe déjà
    if File.exists?(vocal_capture_path)
      yesNo("Un fichier voix existe déjà… Dois-je vraiment le détruire et le remplacer ?") || return
      File.unlink(vocal_capture_path)
    end

    # Précaution : le fichier capture.mp4 doit impérativement
    # exister
    unless File.exists?(mp4_path)
      unless src_path(noalert=true).nil?
        notice "Je dois fabriquer le mp4 de la capture des opérations."
        capture_to_mp4
      else
        error("Il faut capturer les opérations au préalable !")
        puts "\n\nTu peux le faire à l'aide de la commande :\n\n\tvite-faits assistant #{name} pour=capture"
        puts "\n\n"
        return false
      end
    end

    clear
    notice "Nous allons enregistrer la voix finale"
    puts <<-EOF

Pour pouvoir opérer confortablement, nous avons deux solutions.

Solution A : enregistrer la voix sans la vidéo, en la lisant au
             rythme déterminé par le fichier des opérations.

Solution B : enregistrer la voix en suivant la vidéo, en passant
             aux textes suivant par une touche clavier.

Note : pour le moment, seule la solution B est utilisable.

    EOF
    case (getChar("Quelle solution choisis-tu ?")||'').downcase
    when 'a' then assistant_voix_finale_without_video || return
    when 'b' then assistant_voix_finale_with_video || return
    else return error "Je ne connais pas ce choix, j'abandonne."
    end

    clear
    notice "Achèvement de l'enregistrement de la voix."
    puts <<-EOT

Attention, l'enregistrement du son n'est peut-être pas
encore terminé (j'enregistre 20 secondes de plus que la
vidéo de capture, pour être sûr).

Pour finaliser la voix, l'éditer avec Audacity.

Pour l'assembler avec la vidéo de capture, jouer la commande :

  vite-faits assemble_capture #{name}

Si tu veux refaire cette voix, relance la même commande.


    EOT


  rescue NotAnError => e
    unless e.message.nil? || e.message == ''
      error e.message
    end
    error "OK, j'abandonne."
  end

  def assistant_voix_finale_without_video
    clear
    operations = get_operations
    notice "Enregistrement de la voix sans la vidéo"
    yesNo("Es-tu prêt à enregistrer ? (je compterai 5 secondes)") || return
    decompte("Démarrage dans %{nombre_secondes}", 5)
    clear
    operations.each do |operation|
      if operation[:duration]
        end_sleep_time = Time.now.to_i + operation[:duration]
      end
      puts "\n\nDIRE : #{operation[:voice]}"
      # On compte le temps qui reste à attendre par rapport à la durée
      # voulue.
      if operation[:duration]
        sleep_reste = end_sleep_time - Time.now.to_i
      else
        sleep_reste = 1
      end
      sleep sleep_reste
    end

    return true
  end

  def assistant_voix_finale_with_video

    operations = get_operations
    clear
    notice "Enregistrement de la voix avec la vidéo"
    mp4_capture_exists?(required=true) || return

    # On ouvre la vidéo dans quicktime
    `open -a "QuickTime Player" "#{mp4_path}"`
    `open -a Terminal`

    puts <<-EOT

Nous allons commencer par nous installer :

  - vérifier l'entrée du microphone intégré,
  - nous allons spliter l'écran pour avoir la vidéo
    d'un côté et cette console de l'autre :
    • tiens cliqué le bouton vert de QuickTime jusqu'à
      ce que l'écran change d'aspect.
    • place la vidéo à gauche
    • place de la même manière le Terminal à droite
    • ajuste les tailles pour être confortable
      (augmente par exemple la taille de QuickTime s'il
      faut voir des choses précises à l'écran).

  C'est moi qui vais lancer l'enregistrement et la
  vidéo, au bout du décompte.

À la fin du décompte, tu dois :

  - dire le premier texte,
  - CLIQUER SUR LA BARRE ESPACE pour passer au texte
    suivant,
  - répéter ces deux opérations jusqu'à la fin.

Noter qu'il s'agit de cliquer sur la BARRE ESPACE
pour passer à l'étape suivante.

    EOT

    # Déterminer la longueur de la vidéo pour savoir combien de
    # temps il faut enregistrer le son
    duree_capture = Video.dureeOf(mp4_path)
    duree_voice = duree_capture + 20 # au cas où

    yesOrStop("Es-tu prêt ? (je vais compter 10 secondes avant de commencer)")
    decompte("Démarrage de l'enregistrement dans %{nombre_secondes}",5)

    # Mettre en route l'enregistrement
    # cmd = "ffmpeg -f avfoundation -i \":0\" -t 10 \"#{vocal_capture_path}\" &"
    cmd = "#{VOICE_RECORDER_PATH} \"#{vocal_capture_path}\" #{duree_voice}"
    system(cmd)
      # Ici, on doit utiliser system pour que ça joue vraiment dans
      # le background

    # Lancement de la vidéo dans QuickTime
    `osascript <<EOS
tell application "QuickTime Player"
	tell front document
		set audio volume to 0
		set current time to 0
		play
	end tell
end tell
EOS`

    operations.each_with_index do |operation, index|
      clear
      if index > 0
        puts "\n\n(#{operations[index-1][:voice]})"
      end
      notice "\n\n\nDIRE : « #{operation[:voice]} »"
      if operations[index+1]
         puts "\n\n\n(suivant : #{operations[index+1][:voice]})"
       end
      SPACEOrQuit("Passer au texte suivant ?")
    end

    notice "\n\nLa voix a été enregistrée dans le fichier ./Voix/voice.mp4."
    return true
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
