# encoding: UTF-8
=begin
  Module pour créer le tutoriel avec un assistant
=end
class ViteFait
class << self

  def create_with_assistant
    Command.clear_terminal
    notice "=== Bienvenue dans l'assistant de création de tutoriels “vite-faits” ==="
    notice "\nNous allons créer ensemble le tutoriel de A à Z, de la mise en place à la diffusion et l'annonce."
    notice "Note : on peut aussi reprendre la création là où on s'est arrêté."

    # On demande le nom
    tuto_name = ask_for_tuto_name || return

    # On crée une instance, le traitement sera plus facile
    tuto = new(tuto_name)

    # Si le tutoriel est déjà achevé est annoncé, rien à faire
    if tuto.completed_and_published?
      if COMMAND.options[:force]
        error "Désolé, je ne sais pas encore forcer l'assistant à traiter une création forcée."
        return error "Vous pouvez, en attenand, détruire certains éléments manuellement."
      else
        notice "Le tutoriel “#{tuto.titre}” est déjà achevé et publié. Il n'y a plus rien à faire dessus…"
        puts "Si vraiment, tu veux recommencer utilise l'option `--force` avec l'assistant."
        return
      end
    end

    if tuto.exists?
      yesOrStop("Ce tutoriel existe déjà. Dois-je en poursuivre la création ?")
      puts "Poursuite de la création de #{tuto.name}. Faisons le point…"
    else
      tuto.create(nomessage = true)
      COMMAND.options.merge!(silence: false)
    end

    tuto.assiste_creation
    notice "\nTerminé !"

  rescue NotAnError => e
    # Interruption de la création
    error e.message if e.message
    notice "\n\nOK, on s'arrête là."
    notice "Tu pourras reprendre n'importe quand on tapant à nouveau le nom du dossier '#{tuto.name}'"
  ensure
    print "\n\n\n"
  end

  # ---------------------------------------------------------------------
  #   Méthodes de demande
  # ---------------------------------------------------------------------
  def ask_for_tuto_name
    tuto_name = nil
    begin
      tuto_name = prompt("Nom du tutoriel")
      if tuto_name.nil?
        yesOrStop('Voulez-vous vraiment arrêter ?')
      end
      if tuto_name.gsub(/[a-z\-]/,'') != ''
        error "Un nom de tutoriel ne doit comporter que des lettres minuscules et le signe moins."
        tuto_name = nil
      end
    end while tuto_name.nil?

    return tuto_name
  end


end #/<<self


  # ---------------------------------------------------------------------
  #   INSTANCE
  # ---------------------------------------------------------------------

  def assiste_creation

    ask_for_generales_informations

    ask_for_titre_recorded  unless titre_is_recorded?
    convert_titre_final     unless titre_final_converted?

    ask_for_vignette_jpeg   unless vignette_finale_existe?

    ask_for_main_capture    unless capture_is_recorded?

    ask_for_record_voice    unless voice_capture_exists?

    proceed_assemblage      unless video_finale_existe?

    ask_for_upload_video    unless video_uploaded_on_youtube?
    ask_for_youtube_id      unless youtube_id_defined?

    ask_for_annonce_facebook  unless annonce_facebook_deposed?
    ask_for_annonce_scrivener unless annonce_forum_scrivener_deposed?

    finale_message

  end #/ assistant de l'instance

  # --- LES SOUS-MÉTHODES D'ASSISTANCE ---

  def ask_for_generales_informations
    # Les informations générales dont on a besoin
    ask_for_titre        unless titre
    ask_for_titre_en     unless titre_en
    ask_for_description  unless description
    # On enregistre les informations
    if titre || titre_en || description
      informations.set({titre: titre, titre_en:titre_en, description:description})
      # notice "Informations enregistrées."
    else
      notice "Aucune information pour le moment. Il faudra penser à les rentrer."
    end
  end #/ask_for_generales_informations


  # Pour l'enregistrement du titre animé
  def ask_for_titre_recorded
    clear
    notice "Nous devons enregistrer LE TITRE ANIMÉ"
    puts <<-EOT

Je vais ouvrir le modèle, il te suffira alors de :

- régler la largeur de fenêtre et de faire un essai
- régler l'enregistrement (Cmd+Maj+5), sans son.
- t'assurer que c'est tout l'écran qui est capturé
- lancer l'enregistrement et taper aussitôt le titre
- arrêter la capture assez vite
- déplacer le fichier capturé dans le dossier Titre.

Le titre à écrire est : « #{titre} ».
EOT
    yesOrStop("Clique 'y' pour que j'ouvre le titre modèle.")
    open_titre(nomessage = true)
    COMMAND.options.merge!(silence: false)
    # Ouvrir aussi le dossier des captures et le dossier du tutoriel
    ViteFait.open_folder_captures
    open_in_finder(:chantier)
    yesOrStop("Tape 'y' lorsque tu auras fini, pour que je puisse finaliser le titre.")
    unless titre_is_recorded?
      yesOrStop("As-tu bien déplacé le fichier .mov dans le dossier 'Titre' ?\nSinon, ne tape rien, fais-le — sans changer le nom —\net reviens taper 'y'.")
    end
    unless titre_is_recorded?
      raise NotAError.new("Tu n'as pas enregistré le titre. je dois renoncer.")
    end
  end #/ask_for_titre_recorded


  # Convertir le titre final
  def convert_titre_final
    notice "* Conversion du titre.mov en titre.mp4…"
    sleep 4
    titre_to_mp4
    unless titre_final_converted?
      error "Bizarrement, le titre n'a pas pu être converti…"
      raise NotAError.new("Je dois m'arrêter là.")
    end
  end #/convert_titre_final


  # Assister la fabrication de la vignette finale
  def ask_for_vignette_jpeg
    clear
    notice "Nous devons créer LA VIGNETTE"
    puts <<-EOT

Cette vignette sera utile dans YouTube et sur le forum Scrivener
Je vais ouvrir le modèle. Il suffira de :

- régler le titre,
- exporter l'image au format JPEG.

Noter que ce fichier Gimp est une copie de l'original.
On peut donc le modifier et l'enregistrer sans souci.

Le titre à écrire est : « #{titre} ».

    EOT

    yesOrStop("Ouvrir le modèle ?")
    open_vignette
    yesOrStop("Tape 'y' lorsque tu auras fini, pour que nous puissions poursuivre.")

    unless vignette_finale_existe?
      raise NotAnError.new("Tu n'as pas créé la vignette finale… Je dois renoncer.")
    end

  end #/ask_for_vignette_jpeg

  # Assistance de l'enregistrement de la capture principale des opérations
  def ask_for_main_capture
    clear
    notice "Enregistrement des OPÉRATIONS"
    puts <<-EOT

Voilà le gros morceau ! Il s'agit de produire le fichier .mov qui
va contenir toutes les opérations capturées en vidéo.
    EOT

    unless file_operations_exists?
      notice <<-EOT

Il n'existe pas de fichiers opérations. S'il y en avait un, je
pourrais lire les opérations à exécuter en même temps, ce qui
faciliterait le travail.

Pour le faire, interrompt la procédure en répondant 'y' à la
question suivante, puis revient ici en mettant le même titre
("#{name}")
      EOT
      if yesNo("Veux-tu produire le fichier des opérations ?")
        create_file_operations
        return
      else
        # On poursuit normalement
      end
    end

    puts <<-EOT

Il faut :

  - préparer le projet Scrivener (que je vais ouvrir),
  - brancher ton casque iPhone pour enregistrer la voix,
  - taper Cmd+Alt+H pour masquer les autres applications,
  - taper Cmd+Maj+5 pour demander la capture,
  - s'assurer que tout l'écran est capturé
  - s'assurer que l'enregistrement du son est activé
    (même si aucune voix n'est enregistrée),
  - lancer la capture,
  - exécuter les opérations,
  - arrêter la capture à la fin des opérations.

Après la capture :
  - glisser le fichier capturé (le dossier des captures est ouvert)
    dans le dossier du tutoriel (qui est ouvert aussi)
  - revenir ici pour cliquer 'y' et poursuivre,
  - Ouf !

    EOT

    @lire_les_operations = false
    if file_operations_exists?
      @lire_les_operations = yesNo("Dois-je lire le fichier des opérations ?")
    else
      puts "-- Pas de fichiers opérations à lire."
    end

    yesOrStop("Tape 'y' dès que tu es prêt et j'ouvre le fichier Scrivener.")

    ViteFait.open_folder_captures
    open_in_finder(:chantier)
    open_scrivener_file

    if @lire_les_operations
      COMMAND.options.merge!(silence: true)
      say_operations
      COMMAND.options.merge!(silence: false)
    end

    yesOrStop("Tout est prêt ? La capture a été faite ? Nous pouvons poursuivre ?")

    if src_path(noalert=true).nil?
      error "[NON FATAL] Je ne trouve pas le fichier .mov dans le dossier du tutoriel."
      yesOrStop("As-tu pensé à le glisser depuis le dossier capture jusqu'au dossier de #{name} ? (tel quel, sans changer de nom).\nSinon ne tape rien, fais-le et reviens taper 'y' ici.")
      if src_path(noalert=true).nil?
        raise NotAnError.new("[FATAL] Je ne trouve toujours pas le fichier… Je dois renoncer.")
      end
    end
  end #/ask_for_main_capture

  # Méthode qui assiste à l'enregistrement de la voix si
  # nécessaire
  def ask_for_record_voice
    yesNo("Veux-tu procéder à l'enregistrement séparé de la voix ?") || return
    # S'il existe un fichier avec les opérations, on va écrire le texte à
    # l'écran, ou le faire défiler progressivement.
    assistant_voix_finale
  end

  # Méthode qui procède à l'assemblage final des éléments
  def proceed_assemblage
    clear
    notice "Je vais procéder à l'assemblage. Il faudra atten-\ndre un peu."
    puts "\nC'est assez long, pendant ce temps, tu peux vaquer\nà d'autres occupations."
    sleep 5
    assemble(nomessage = true)

    clear
    puts <<-EOT
L'assemblage a été effecuté avec succès, mais peut-être faut-il le
modifier dans ScreenFlow.

    EOT
    yesOrStop("Prêt à poursuivre ?")
  end #/proceed_assemblage


  # Assiste à l'upload de la vidéo sur YouTube
  def ask_for_upload_video
    clear
    notice "Tu dois procéder à l'UPLOAD SUR YOUTUBE."
    puts <<-EOT
Je vais ouvrir ta chaine et il te suffira de déposer la vidéo.

Tu pourras mettre en description :
Dans la série des vites-faits, un tutoriel #{description}

Si tu n'as pas le bon compte, celui de cette chaine est avec le compte
yahoo et le code normal.

    EOT
    yesOrStop("Es-tu prêt ?")
    chaine_youtube
    yesOrStop("La vidéo est uploadée ? Prêt à poursuivre ?")
    unless video_uploaded_on_youtube?
      informations.set(uploaded_on_youtube: true)
    end
  end #/ask_for_upload_video


  # Demande l'identifiant de la vidéo YouTube
  def ask_for_youtube_id
    clear
    notice "Nous devons définir l'ID YOUTUBE de la vidéo."
    begin
      yid = prompt("ID youtube")
      if yid.nil?
        yesOrStop("Il faut entrer l'ID de la vidéo. Dois-je poursuivre ?")
      end
    end while yid.nil?
    informations.set(youtube_id: yid)
  end #/ask_for_youtube_id


  # Assistant pour l'annonce du tutoriel sur FaceBook
  def ask_for_annonce_facebook
    clear
    notice "Nous allons procéder à l'annonce sur FB."
    yesOrStop("Prêt ?")
    annonce(:facebook)
    yesOrStop("Prêt à poursuivre ?")
  end #/ask_for_annonce_facebook


  # Assistant pour l'annonce sur le forum Scrivener
  def ask_for_annonce_scrivener
    clear
    notice "Nous allons procéder à l'annonce sur le forum Scrivener."
    yesOrStop("Prêt ?")
    annonce(:scrivener)
    yesOrStop("Prêt à poursuivre ?")
  end #/ask_for_annonce_scrivener


  def finale_message
    clear
    notice "Nous en avons terminé avec ce tutoriel !"
    notice "Bravo ! 👏 👏 👏"
    notice "À quand le prochain ?\n\n"
  end #/finale_message

  # --- STATES ---

  def completed_and_published?
    File.exists?(completed_path) &&
      video_uploaded_on_youtube? &&
      annonce_forum_scrivener_deposed? &&
      annonce_facebook_deposed?
  end

  def vignette_finale_existe?
    File.exists?(vignette_path)
  end

  def titre_is_recorded?
    titre_mov && File.exists?(titre_mov)
  end

  def titre_final_converted?
    titre_mov && File.exists?(titre_mp4)
  end

  def capture_is_recorded?
    src_path(noalert = true) && File.exists?(src_path)
  end

  def capture_ts_existe?
    src_path(noalert = true) && File.exists?(mp4_path)
  end

  def video_finale_existe?
    File.exists?(completed_path)
  end

  def video_uploaded_on_youtube?
    informations.data[:uploaded_on_youtube]
  end

  def annonce_facebook_deposed?
    informations.data[:annonce_facebook]
  end

  def annonce_forum_scrivener_deposed?
    informations.data[:annonce_scrivener]
  end

  def youtube_id_defined?
    informations.data[:youtube_id]
  end

  def infos_existent?
    return true # TODO
  end


  def ask_for_titre
    clear
    puts "Nous devons déterminer le titre humain du tutoriel"
    puts "Le choisir avec soin car il sera utilisé dans les annonces et autre."
    puts "(mais vous pourrez toujours le redéfinir par vite-faits infos #{name} titre='new_titre')"
    res = prompt("Titre humain")
    clear
    if res.nil?
      puts "OK, pas de titre pour le moment…"
    else
      @titre = res
    end
  end

  def ask_for_titre_en
    puts "J'ai besoin du titre anglais (pour le forum Scrivener)"
    puts "(tu pourras toujours le redéfinir par vite-faits infos #{name} titre_en='new_titre')"
    res = prompt("Titre anglais")
    clear
    if res.nil?
      puts "OK, pas de titre anglais pour le moment…"
    else
      @titre_en = res
    end
  end

  def ask_for_description
    puts "Une description en une phrase, pour accompagner les messages."
    res = prompt("Description")
    clear
    if res.nil?
      puts "OK, pas de description pour le moment…"
    else
      @description = res
    end
  end

  # Raccourci
  def yesOrStop(question); self.class.yesOrStop(question) end

end #/ViteFait
