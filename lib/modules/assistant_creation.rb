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

    # On crée une instance, ça sera plus facile
    tuto = new(tuto_name)

    # Si le tutoriel est déjà achevé est annoncé, rien à faire
    if tuto.completed_and_published?
      if COMMAND.options[:force]
        error "Désolé, je ne sais pas encore forcer l'assistant à traiter une création forcée."
        return
      else
        notice "Le tutoriel “#{tuto.titre}” est déjà achevé et publié. Il n'y a plus rien à faire dessus…"
        puts "Si vraiment, tu veux recommencer utilise l'option `--force` avec l'assistant."
        return
      end
    end

    if tuto.exists?
      if yesNo("Ce tutoriel existe déjà. Dois-je en poursuivre la création ?")
        puts "Poursuite de la création de #{tuto.name}. Faisons le point…"
      else
        return
      end
    else
      notice "Je crée le dossier et tout le tralala du tutoriel…"
      tuto.create
    end

    if tuto.assiste_creation
      notice "\nTerminé !"
    else
      notice "\n\nOK, on s'arrête là."
      notice "Tu pourras reprendre n'importe quand on tapant à nouveau le nom du dossier '#{tuto.name}'"
    end

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
        if yesNo("Voulez-vous vraiment arrêter ?")
          return nil
        end
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

    unless titre_is_recorded?
      clear
      notice "Nous devons enregistrer LE TITRE ANIMÉ"
      puts <<-EOT

Je vais ouvrir le modèle, il te suffira alors de :
  - régler la largeur de fenêtre et de faire un essai
  - régler l'enregistrement (Cmd+Maj+5), sans son.
  - s'assurer que c'est tout l'écran qui est capturé
  - lancer l'enregistrement et taper aussitôt le titre
  - arrêter la capture assez vite
  - déplacer le fichier capturé dans le dossier Titre.
EOT
      if yesNo("Clique 'y' pour que j'ouvre le titre modèle.")
        open_titre(nomessage = true)
        # Ouvrir aussi le dossier des captures et le dossier du tutoriel
        ViteFait.open_folder_captures
        open_in_finder(:chantier)
        if !yesNo("Tape 'y' lorsque tu auras fini, pour que je puisse finaliser le titre.")
          return false
        end
        unless titre_is_recorded?
          if !yesNo("As-tu bien déplacé le fichier .mov dans le dossier 'Titre' ?\nSinon, ne tape rien, fais-le — sans changer le nom —\net reviens taper 'y'.")
            return false
          end
        end
      else
        return false
      end

      unless titre_is_recorded?
        error "Tu n'as pas enregistré le titre. je dois renoncer."
        return false
      end
    end

    unless titre_final_converted?
      notice "Conversion du titre.mov en titre.mp4…"
      sleep 4
      titre_to_mp4
      unless titre_final_converted?
        error "Bizarrement, le titre n'a pas pu être converti…"
        return error "Je dois m'arrêter là."
      end
    end

    unless vignette_finale_existe?
      clear
      notice "Nous devons créer LA VIGNETTE"
      puts <<-EOT

Cette vignette sera utile dans YouTube et sur le forum Scrivener
Je vais ouvrir le modèle. Il suffira que :
  - tu règles le titre,
  - tu exportes au format JPEG.

Noter que ce fichier Gimp est une copie de l'original.
Vous pouvez donc le modifier et l'enregistrer sans souci.
      EOT
      if yesNo("Ouvrir le modèle ?")
        open_vignette
        if !yesNo("Tape 'y' lorsque tu auras fini, pour que nous puissions poursuivre.")
          return false
        end
      else
        return false
      end

      unless vignette_finale_existe?
        return error "Tu n'as pas créé la vignette finale… Je dois renoncer."
      end
    end


    unless capture_is_recorded?
      clear
      notice "Enregistrement des OPÉRATIONS"
      puts <<-EOT

Voilà le gros morceau ! Il s'agit de produire le fichier .mov qui
va contenir toutes les opérations à exécuter.

Voilà la procédure :

    - préparer le fichier Scrivener (que je vais ouvrir),
    - brancher ton casque iPhone pour enregistrer la voix,
    - Cmd+Alt+H pour masquer les autres applications,
    - taper Cmd+Maj+5 pour demander la capture,
    - s'assurer que tout l'écran soit capturé
    - régler l'enregistrement du son (même si aucune voix, obligatoire)
    - lancer la capture,
    - exécuter les opérations.
    - arrêter la capture à la fin des opérations.

Après la capture :
    - glisser le fichier capturé (le dossier des captures est ouvert)
      dans le dossier du tutoriel (qui est ouvert aussi)
    - revenir ici pour cliquer 'y' et poursuivre,
    - Ouf !

      EOT

      unless yesNo("Tape 'y' dès que tu es prêt et j'ouvre le fichier Scrivener.")
        return false
      end
      ViteFait.open_folder_captures
      open_in_finder(:chantier)
      open_scrivener_file

      unless yesNo("Tout est prêt ? La capture a été faite ? Nous pouvons poursuivre ?")
        return false
      end

      if src_path(noalert=true).nil?
        error "[NON FATAL] Je ne trouve pas le fichier .mov dans le dossier du tutoriel."
        unless yesNo("As-tu pensé à le glisser depuis le dossier capture jusqu'au dossier de #{name} ? (tel quel, sans changer de nom).\nSinon ne tape rien, fais-le et reviens taper 'y' ici.")
          return false
        end
        if src_path.nil?
          return error "[FATAL] Je ne trouve toujours pas le fichier… Je dois renoncer."
        end
      end
    end

    # On peut enfin procéder à l'assemblage
    unless video_finale_existe?
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
      unless yesNo("Prêt à poursuivre ?")
        return false
      end
    end

    unless video_uploaded_on_youtube?
      clear
      notice "Tu dois procéder à l'UPLOAD SUR YOUTUBE."
      puts <<-EOT
Je vais ouvrir ta chaine et il te suffira de déposer la vidéo.

Tu pourras mettre en description :
Dans la série des vites-faits, un tutoriel #{description}

Si tu n'as pas le bon compte, celui de cette chaine est avec le compte
yahoo et le code normal.

      EOT
      yesNo("Es-tu prêt ?") || (return false)
      chaine_youtube
      yesNo("La vidéo est uploadée ? Prêt à poursuivre ?") || (return false)
      unless video_uploaded_on_youtube?
        informations.set(uploaded_on_youtube: true)
      end
    end

    unless youtube_id_defined?
      clear
      notice "Nous devons définir l'ID YOUTUBE de la vidéo."
      yid = prompt("ID youtube")
      yid || (return false)
      informations.set(youtube_id: yid)
    end

    unless annonce_facebook_deposed?
      clear
      notice "Nous allons procéder à l'annonce sur FB."
      unless yesNo("Prêt ?")
        return false
      end
      COMMAND.params.merge!(pour: 'facebook')
      annonce
      yesNo("Prêt à poursuivre ?") || (return false)
    end

    unless annonce_forum_scrivener_deposed?
      clear
      notice "Nous allons procéder à l'annonce sur le forum Scrivener."
      unless yesNo("Prêt ?")
        return false
      end
      COMMAND.params.merge!(pour: 'scrivener')
      annonce
      unless yesNo("Prêt à poursuivre ?")
        return false
      end
    end

    clear
    notice "Nous en avons terminé avec ce tutoriel !"
    notice "Bravo ! 👏 👏 👏"
    notice "À quand le prochain ?"

    unless infos_existent?
      input_infos
    end

    return true
  end #/ assistant de l'instance


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

  def clear
    puts "\n\n"
    Command.clear_terminal
  end

end #/ViteFait
