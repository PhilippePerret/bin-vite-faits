# encoding: UTF-8
=begin

  Module d'assistance pour l'enregistrement de la voix
  finale du tutoriel à partir du fichier des opérations.

=end

# Assistant pour l'enregistrement de la voix finale
# La méthode passe en revue chaque opération en écrivant le texte à lire,
# en maintenant le rythme adéquat
=begin
=end
def exec(options = nil)

  avec_assistant = operations_are_defined?

  clear
  notice "=== Enregistrement de la voix ===\n\n"

  if avec_assistant
    puts "(avec assistant pour les textes)"
  else
    puts <<-EOT
(si un fichier des opérations existait, je pourrais
 t'accompagner de façon plus significative en te
 distant les textes)"
    EOT
  end
  # Dans le cas où on force l'assistant de l'enregistrement
  # de la voix directement (alors que lorsque l'on est sur
  # l'assistant de création, on ne passe pas par là si le
  # fichier existe déjà)
  if File.exists?(vocal_capture_path)
    yesOrStop("Un fichier voix existe déjà… Dois-je vraiment le détruire et le remplacer ?")
    File.unlink(vocal_capture_path)
  end

  # Précaution : le fichier capture.mp4 doit impérativement
  # exister. Si ce n'est pas le cas, on le fabrique dans le
  # cas où le fichier .mov existe. Si aucun fichier capture
  # n'existe, on doit s'arrêter là.
  # Noter que dans la version de l'assistant complet, on serait
  # arrêté bien avant d'arrive là. Le fichier mp4 est forcément
  # fabriqué.
  unless File.exists?(mp4_path)
    unless src_path(noalert=true).nil?
      notice "Je dois fabriquer le mp4 de la capture des opérations."
      capture_to_mp4
    else
      raise NotAnError.new("Il faut impérativement capture les opérations au préalable.\n\tvite-faits assistant #{name} pour=capture")
      return false
    end
  end

  puts <<-EOF

Pour pouvoir opérer confortablement, nous avons deux solutions.

  A:  enregistrer la voix sans la vidéo, en la
      lisant au rythme déterminé par le fichier
      des opérations.

  B:  enregistrer la voix en suivant la vidéo,
      en passant aux textes suivant par une touche
      clavier.

  C:  renoncer pour préparer le fichier des opérations

(Note : pour le moment, A n'est pas opérationnel)

  EOF

  # On va procéder vraiment à l'opération
  # -------------------------------------
  case (getChar("Quelle solution choisis-tu ?")||'').upcase
  when 'A' then assistant_voix_finale_without_video
  when 'B' then assistant_voix_finale_with_video
  when 'C' then raise NotAnError.new
  else raise NotAnError.new("Je ne connais pas ce choix.")
  end

  # On passe ici quand on a fini d'enregistrer la
  # voix.

  if Time.now.to_i < @fin_enregistrement_voix
    reste_secondes = @fin_enregistrement_voix - Time.now.to_i
    puts <<-EOT

Attention, l'enregistrement du son n'est pas encore
terminé. Par prudence, j'enregistre toujours 20 secondes
de plus que la vidéo de capture, pour être sûr.

L'enregistrement se terminera dans #{reste_secondes} secondes.

    EOT
    decompte("Arrêt de l'enregistrement dans %{nombre_secondes}", reste_secondes)
  end

  if File.exists?(vocal_capture_path)
    notice "👍  Voix enregistrée avec succès dans le fichier ./Voix/voice.mp4."
  else
    raise NotAnError.new("Fichier voix (*) introuvable. La voix n'a pas été enregistrée.\n(*) #{vocal_capture_path}")
  end

  yesNo("Paré pour la suite ?")

  if yesNo("Veux-tu l'ouvrir dans Audacity pour la peaufiner ?")
    puts "Il faudra enregistrer le résultat au format AIFF (extension '.aiff')"
    sleep 4
    `open -a Audacity "#{vocal_capture_path}"`

    if yesNo("Dois-je convertir le fichier AIFF en fichier MP4 (normal) ?")
      File.exists?(vocal_capture_aiff_path) || raise(NotAnError.new("Impossible de trouver le fichier .aiff… Je ne peux pas prendre le nouveau fichier."))
      File.unlink(vocal_capture_path) if File.exists?(vocal_capture_path)
      cmd = "ffmpeg -i \"#{vocal_capture_aiff_path}\" \"#{vocal_capture_path}\""
      COMMAND.options[:verbose] || cmd << " 2> /dev/null"
      res = `#{cmd}`

      if File.exists?(vocal_capture_path)
        notice "👍  Fichier voice converti avec succès."
        File.unlink(vocal_capture_aiff_path) if File.exists?(vocal_capture_aiff_path)
      else
        raise NotAnError.new("Le fichier voix n'a pas été converti…\n(*) #{vocal_capture_path}")
      end
    end
  end

  yesOrStop("Prêt à poursuivre ?")

end



def assistant_voix_finale_with_video

  operations = get_operations

  clear
  notice "=== Enregistrement de la voix avec la vidéo ==="

  # On ouvre la vidéo dans quicktime
  `open -a "QuickTime Player" "#{mp4_path}"`
  `open -a Terminal`

  puts <<-EOT

Nous allons commencer par mettre en place
l'installation :

- vérifier le niveau de l'entrée du microphone
  intégré,
- nous allons spliter l'écran pour avoir la vidéo
  d'un côté et cette console de l'autre :
  • tiens cliqué le bouton vert de QuickTime jusqu'à
    ce que l'écran change d'aspect.
  • place la vidéo à gauche
  • choisi cette fenêtre du Terminal pour la partie
    droite
  • ajuste les tailles des deux écrans pour être
    confortable (augmente par exemple la taille de
    QuickTime s'il faut voir des choses précises à
    l'écran).

C'est moi qui vais lancer l'enregistrement et la
vidéo, au bout du décompte. Tu n'auras rien à faire
à ce niveau-là.
  EOT

  avec_assistant = operations_are_defined?

  if avec_assistant
    puts <<-EOT

À la fin du décompte, tu dois :

  - dire le premier texte (il sera toujours affiché
    en vert, avec la phrase d'avant et la phrase d'après
    en blanc),
  - cliquer sur LA BARRE ESPACE pour passer au texte
    suivant,
  - répéter ces deux opérations jusqu'à la fin.
    EOT
  else
    puts <<-EOT

À la fin du décompte tu peux commencer le
commentaire de la vidéo.

    EOT

  end

  # Déterminer la longueur de la vidéo pour savoir combien de
  # temps il faut enregistrer le son
  duree_capture = Video.dureeOf(mp4_path)
  duree_voice = duree_capture + 20 # au cas où

  yesOrStop("Es-tu prêt ? (je vais compter 10 secondes avant de commencer)")
  decompte("Démarrage de l'enregistrement dans %{nombre_secondes}",5, 'Audrey')

  # Mettre en route l'enregistrement
  # cmd = "ffmpeg -f avfoundation -i \":0\" -t 10 \"#{vocal_capture_path}\" &"
  cmd = "#{VOICE_RECORDER_PATH} \"#{vocal_capture_path}\" #{duree_voice}"
  system(cmd)
  # La fin de l'enregistrement
  @fin_enregistrement_voix = Time.now.to_i + duree_voice
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

  if avec_assistant
    operations.each_with_index do |operation, index|
      clear
      if index > 0
        puts "\n\n(#{operations[index-1][:voice]})"
      end
      notice "\n\n\n« #{operation[:voice]} »"
      if operations[index+1]
        puts "\n\n\n(suivant : #{operations[index+1][:voice]})"
      end
      SPACEOrQuit("Passer au texte suivant ?")
    end
  else
    # Quand on travaille sans liste d'opération
    yesOrStop("Clique ici quand tu auras terminé (ou 'q' pour renoncer).")
  end
  return true
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
