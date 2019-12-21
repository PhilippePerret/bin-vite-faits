# encoding: UTF-8
=begin

  Module d'assistance pour l'enregistrement de la voix
  finale du tutoriel à partir du fichier des opérations.

=end

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
