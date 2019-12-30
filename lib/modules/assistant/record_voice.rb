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

  avec_assistant = operations_defined?

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
  if File.exists?(record_voice_path)
    yesOrStop("Un fichier voix existe déjà… Dois-je vraiment le détruire et le remplacer ?")
    IO.remove_with_care(record_voice_path,'fichier voix',false)
  end

  # Précaution : le fichier capture.mp4 doit impérativement
  # exister. Si ce n'est pas le cas, on le fabrique dans le
  # cas où le fichier .mov existe. Si aucun fichier capture
  # n'existe, on doit s'arrêter là.
  # Noter que dans la version de l'assistant complet, on serait
  # arrêté bien avant d'arrive là. Le fichier mp4 est forcément
  # fabriqué.
  only_with_durees = false
  unless File.exists?(record_operations_mp4)
    unless record_operations_path(noalert=true).nil?
      notice "Je dois fabriquer le mp4 de la capture des opérations…"
      capture_to_mp4
    else
      # Sans fichier de capture des opérations
      error <<-EOA
\033[1;31mLe fichier de capture des opérations n'existe pas\033[0m, ce qui signifie
que pour enregistrer la voix vous n'avez que la solution avec
les durées, sans vidéo.

Pour lancer la capture : `vitefait assistant pour=capture #{name}`

\033[1;31m(*) Si la capture des opérations doit être accélérée, il faut
              accélérer en conséquence le débit de la voix, ce qui est
              fait en définissant le paramètre `speed=...`.\033[0m
      EOA
      yesNo("Voulez-vous poursuivre ?") || (return false)
      only_with_durees = true
    end
  end

  unless only_with_durees
    puts <<-EOF

Pour pouvoir opérer confortablement, nous avons deux solutions.

  A:  enregistrer la voix sans la vidéo, en la
      lisant au rythme déterminé par le fichier
      des opérations (plus sûre).

  B:  enregistrer la voix en suivant la vidéo,
      en passant aux textes suivant par une touche
      clavier (plus synchrone).

  C:  renoncer pour préparer le fichier des opérations ou
      modifier l'accélérateur (qui vaut actuellement #{informations[:accelerator]}) (*).

(*) Pour le modifier, ajouter le paramètre `speed=val` où val vaut
    2 pour doubler le rythme, 1.5 pour l'augmenter de la moitié de
    sa valeur, etc. Ou définir l'information `accelerator`.

    EOF

    choix = (getChar("Quelle solution choisis-tu ?")||'').upcase
  else
    choix = 'A'
  end

  # Si une accélération a été définie, il faut la prendre
  # en compte. On la met simplement dans le paramètre
  # speed qui pourra être accédé par tous les calculs de
  # durée estimée.
  if COMMAND.params[:speed] || informations[:accelerator]
    COMMAND.params[:speed] ||= informations[:accelerator]
  end

  # ENREGISTREMENT DE LA VOIX
  # -------------------------

  case choix
  when 'A' then assistant_voix_finale_with_durees
  when 'B' then assistant_voix_finale_with_video
  when 'C' then raise NotAnError.new
  else raise NotAnError.new("Je ne connais pas le choix '#{choix}'.")
  end

  # FIN DE L'ENREGISTREMENT DE LA VOIX
  # ----------------------------------


  if Time.now.to_i < @fin_enregistrement_voix
    reste_secondes = @fin_enregistrement_voix - Time.now.to_i
    if reste_secondes > 5
      puts <<-EOT

Attention, l'enregistrement du son n'est pas encore
terminé. Il reste #{reste_secondes.to_i} secondes.

      EOT
    end
    decompte("Stop in… %{nombre_secondes}", reste_secondes)
  end

  if File.exists?(record_voice_path)
    notice "👍  Voix enregistrée avec succès dans le fichier ./Voix/voice.mp4."
    save_last_logic_step
  else
    raise NotAnError.new("Fichier voix (*) introuvable. La voix n'a pas été enregistrée.\n(*) #{record_voice_path}")
  end

  yesOrStop("Paré pour la suite ?")

  case yesNo("Veux-tu l'ouvrir dans Audacity pour la peaufiner ?")
  when true
    require_module('edit_voice_file')
    edition_fichier_voix
  when NilClass
    raise NotAnError.new
  end

  yesOrStop("Prêt à poursuivre ?")

end



def assistant_voix_finale_with_video

  clear
  notice "=== Enregistrement de la voix avec la vidéo ==="

  # On ouvre la vidéo dans quicktime
  `open -a "QuickTime Player" "#{record_operations_mp4}"`
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

  avec_assistant = operations_defined?

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
  duree_capture = Video.dureeOf(record_operations_mp4)
  duree_voice = duree_capture + 20 # au cas où

  yesOrStop("Es-tu prêt ? (je vais compter 10 secondes avant de commencer)")

  # On resette IOConsole notamment pour rafraichir la largeur
  # de la fenêtre après le split-screen de plein écran.
  IOConsole.reset

  decompte("Start in… %{nombre_secondes}",5, 'Audrey')

  # Mettre en route l'enregistrement
  start_voice_recording(duree_voice)

  # Lancement de la vidéo dans QuickTime
  start_quicktime

  if avec_assistant
    operations.each_with_index do |operation, index|
      prev_ope = index > 0 ? operations[index - 1] : nil
      next_ope = operations[index + 1]
      clear
      puts <<-EOT

\033[1;90m(#{prev_ope ? prev_ope.f_voice : '---'})\033[0m



\033[1;32m#{operation.f_voice}\033[0m



\033[1;90m(#{next_ope ? next_ope.f_voice : '---'})\033[0m


      EOT
      SPACEOrQuit("Passer au texte suivant ?") || begin
        stop_quicktime
        raise NotAnError.new()
      end
    end
  else
    # Quand on travaille sans liste d'opération
    yesOrStop("Clique ici quand tu auras terminé (ou 'q' pour renoncer).")
  end
  return true
end


def assistant_voix_finale_with_durees
  clear
  notice "Enregistrement de la voix suivant les durées déterminées"

  accelerator = COMMAND.params[:speed] || 1.0


  yesOrStop("Es-tu prêt à enregistrer ? (je compterai 5 secondes)")
  decompte("Start in… %{nombre_secondes}", 5)

  # Durée d'enregistrement (obligatoire)
  # Si le fichier de capture des opérations existe, on prend simplement
  # sa durée, et dans le cas contraire, on estime la durée d'après
  # le fichier des opérations.
  duree_voice =
    if operations_recorded?
      Video.dureeOf(record_operations_mp4)
    else
      require_module('operations')
      (duree_totale_estimee.to_f / accelerator).round
    end + 10 # marge
  start_voice_recording(duree_voice)

  clear
  operations.each_with_index do |operation, index|
    end_sleep_time = Time.now.to_i + (operation.duree_estimee.to_f / accelerator).round
    prev_ope = index > 0 ? operations[index - 1] : nil
    next_ope = operations[index + 1]
    clear
    puts <<-EOT

\033[1;90m(#{prev_ope ? prev_ope.f_voice : '---'})\033[0m



\033[1;32m#{operation.f_voice}\033[0m



\033[1;90m(#{next_ope ? next_ope.f_voice : '---'})\033[0m


    EOT
    # On compte le temps qui reste à attendre par rapport à la durée
    # voulue.
    sleep_reste = end_sleep_time - Time.now.to_i
    decompte('Suite dans %{nombre_secondes}', sleep_reste)
    # TODO Il faudrait pouvoir capter une touche pour pouvoir
    # interrompre en douceur sans passer par Ctrl-C
  end

  return true
end

# ---------------------------------------------------------------------
#   Méthodes fonctionnelles
# ---------------------------------------------------------------------

# Mise en route de l'enregistrement
# +Params+::
#   +duree_voice+::[Integer]  Il est impératif de préciser la durée
#                             de l'enregistrement avec cet argument.
def start_voice_recording(duree_voice)
  # cmd = "ffmpeg -f avfoundation -i \":0\" -t 10 \"#{record_voice_path}\" &"
  cmd = "#{VOICE_RECORDER_PATH} \"#{record_voice_path}\" #{duree_voice}"
  system(cmd)
  # Ici, on doit utiliser system pour que ça joue vraiment dans
  # le background
  # La fin de l'enregistrement (pour bien l'attendre à la fin)
  @fin_enregistrement_voix = Time.now.to_i + duree_voice
end

def start_quicktime
  `osascript <<EOS
tell application "QuickTime Player"
tell front document
  set audio volume to 0
  set current time to 0
  play
end tell
end tell
EOS`
end
def stop_quicktime
  `osascript <<EOS
tell application "QuickTime Player"
tell front document
  stop
  set current time to 0
end tell
end tell
EOS`
end
