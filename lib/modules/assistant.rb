# encoding: UTF-8
=begin
  Module pour créer le tutoriel avec un assistant
=end
class ViteFait
class << self

  # Méthode principale de la création d'un tutoriel (ou la reprise de
  # la création d'un tutoriel) de façon entièrement assistée.
  def create_with_assistant

    clear
    notice <<-EOT
=== Bienvenue dans l'assistant de création de tutoriels “vite-faits” ===

Nous allons créer ensemble le tutoriel de A à Z, de la mise
en place à la diffusion et les annonces.
Note : on peut aussi reprendre la création là où on s'est
arrêté.
    EOT

    # On demande le nom
    tuto = nil
    tuto_name = COMMAND.folder || ask_for_tuto_name || return

    # On crée une instance, le traitement sera plus facile ensuite
    tuto = new(tuto_name)

    if tuto.exists?
      ask_when_exists_or_completed(tuto)
    else
      create_new_tutorial(tuto)
    end

    tuto.make_pre_bilan_operatoire

    tuto.set_generales_informations   unless tuto.infos_defined?(false)
    tuto.record_titre                 unless tuto.titre_is_recorded?(false)
    tuto.convert_titre_final          unless tuto.titre_final_converted?(false)
    tuto.build_vignette_jpeg          unless tuto.vignette_finale_existe?(false)

    tuto.define_operations            unless tuto.operations_defined?(false,false)

    # Enregistrement des opérations
    tuto.record_operations            unless tuto.operations_recorded?(false,false)

    # On finalise le fichier capture, pour qu'il corresponde à ce dont
    # on a besoin pour enregistrer la voix. Notamment au niveau de la
    # vitesse de la vidéo
    tuto.ask_capture_mov_to_mp4       unless tuto.mp4_capture_exists?(false,false)

    # Enregistrement de la voix
    tuto.ask_for_record_voice         unless tuto.voice_capture_exists?(false,false)

    # S'il existe un fichier .aiff on regarde s'il est plus jeune que le
    # fichier mp4 dans lequel cas on demande à refaire le mp4.
    tuto.check_for_reconvert_voice    if File.exists?(tuto.record_voice_aiff)

    # Assemblage de la capture des opérations et de la capture de
    # la voix (ou du fichier voix)
    tuto.proceed_assemblage           unless tuto.video_finale_existe?(false)

    tuto.ask_for_upload_video         unless tuto.video_uploaded?(false)

    tuto.ask_for_youtube_id           unless tuto.youtube_id_defined?(false)

    tuto.ask_for_annonce_facebook     unless tuto.annonce_facebook_deposed?(false)
    tuto.ask_for_annonce_scrivener    unless tuto.annonce_FB_deposed?(false)

    tuto.finale_message

  rescue NotAnError => e
    # Interruption de la création
    e.puts_error_if_message
    if tuto.nil?
      notice "\n\nOK, on s'arrête là."
    else
      notice <<-EOM

OK, on s'arrête là pour la construction du
tutoriel “#{tuto.name}”. Tu pourras reprendre
n'importe quand on tapant à nouveau la commande :

    vite-faits assistant #{tuto.name}
      EOM
    end
  ensure
    print "\n\n\n"
  end

  # ---------------------------------------------------------------------
  #   Méthodes de demande
  # ---------------------------------------------------------------------
  def ask_for_tuto_name
    require_relative 'assistant/tutorial_name'
    exec
  end

  def ask_when_exists_or_completed(tuto)
    require_relative 'assistant/when_exists_and_completed'
    exec(tuto)
  end

  # Création d'un nouveau tutoriel
  def create_new_tutorial(tuto)
    # Si le tutoriel n'existe pas, on met tout de suite son lieu, pour
    # savoir où le créer.
    unless tuto.exists?
      tuto.instance_variable_set('@lieu', :chantier)
    end
    tuto.create
  end


end #/<<self


  # ---------------------------------------------------------------------
  #   INSTANCE
  # ---------------------------------------------------------------------

  # Avant de procéder à la création assistée, je procède à un pré-bilan
  # pour savoir, par exemple, quels fichiers existent, pour savoir,
  # notamment, si un fichier a été supprimé, qui doit être refait et si
  # cette refaction doit entrainer la destruction des fichiers suivants
  # On a une vérification aussi au niveau des dates.
  def make_pre_bilan_operatoire
    # Si le dossier n'existe pas, rien à faire
    exists? || return
    table_prebilan = []
    DATA_KEYS_FILES_OPERATION.each do |kfile|
      data_file = {}
      data_file.merge!(DATA_ALL_FILES[kfile.to_sym])
      if data_file[:relpath]
        path = File.join(current_folder, (data_file[:relpath] % {name: name}))
        existe  = !!File.exists?(path)
        mtime   = existe ? File.stat(path).mtime.to_i : nil
      end
      if data_file[:informations]
        mtime = nil
        existe = true # si tout est OK
        data_file[:informations].each do |kinfo|
          next if informations[kinfo] === true
          existe = false
          break
        end
      end
      data_file.merge!({
        exists: existe,
        time:   mtime
        })
      table_prebilan << data_file
    end

    table_prebilan += [
      {id: 'upload',        hname: "Téléchargement sur YouTube",  exists:!infos[:youtube_id].nil?},
      {id: 'annonce_fb',    hname: "Annonce Facebook",            exists: infos[:annonce_FB]},
      {id: 'annonce_Scriv', hname:"Annonce Forum Scrivener",      exists: infos[:annonce_Scriv]}
    ]

    # puts "\n\n---- #{table_prebilan}"

    # On va analyser ces informations
    # Fonctionnement :
    #   Le principe est que si un élément a été supprimé et
    #   qu'il existe des éléments suivant, on doit demander
    #   s'il faut supprimer ces éléments pour actualiser la
    #   chose.
    puts "\n\n"
    table_prebilan.each_with_index do |bilan, index|
      puts "#{bilan[:hname].ljust(60,'.')} #{bilan[:exists].inspect}"
      bilan[:exists] && next
      # Un élément qui n'existe pas
      # Est-ce qu'un élément après existe ?
      table_prebilan[(index+1)..-1].each do |cbilan|
        if cbilan[:exists]
          # => Il faut demander
          question = <<-EOQ
Pour “#{name}”, l'élément #{bilan[:hname]}
n'existe plus, mais l'élément suivant #{cbilan[:hname]}
existe (ainsi, peut-être, que d'autres éléments
encore après).

Que dois-je faire ?

  A. Ne refaire que l'élément #{bilan[:hname]} et
     garder les autres.

  B. Supprimer tous les éléments après pour les
     refaire ou les actualiser.

          EOQ
          puts question
          case (getChar("Ton choix :")||'').upcase
          when '' then raise NotAnError.new()
          when 'A'
            return # sans rien faire
          when 'B'
            remove_files_from(index+1)
          else
            raise NotAnError.new("Ce choix est inconnu.")
          end
        end
      end
    end
  end

  # Effacer tous les fichiers depuis l'étape bilan d'index
  # +index+ (dans DATA_ALL_FILES)
  def remove_files_from(index)
    keyFile = DATA_KEYS_FILES_OPERATION[index].to_sym
    datFile = DATA_ALL_FILES[keyFile]
    question = "Confirmes-tu bien la suppression de tous les fichiers existants après l'étape “#{datFile[:hname]}” ?"
    yesNo(question) || return
    DATA_KEYS_FILES_OPERATION[index..-1].each do |kfile|
      dfile = DATA_ALL_FILES[kfile.to_sym]
      dfile[:relpath] || next # pas un fichier
      path = File.join(current_folder, (dfile[:relpath] % {name: name}))
      File.exists?(path) || next # le fichier n'existe pas
      IO.remove_with_care(path,"fichier #{dfile[:hname]}",true)
    end
  end

  def set_generales_informations
    activate_terminal
    yesNo("Prêt à définir les informations générales pour “#{name}” ?") || raise(NotAnError.new)
    require_relative 'assistant/generales_informations'
    exec
  end

  def record_titre
    yesNo("Prêt pour enregistrer le titre animé de “#{name}” ?") || raise(NotAnError.new)
    require_relative 'assistant/record_titre'
    exec
  end

  def build_vignette_jpeg
    yesNo("Prêt pour fabriquer la vignette de “#{name}” ?") || raise(NotAnError.new)
    require_relative 'assistant/build_vignette_jpeg'
    exec
  end


  # --- LES SOUS-MÉTHODES D'ASSISTANCE ---


  # Convertir le titre final
  def convert_titre_final
    notice "* “#{name}”, conversion du titre.mov en titre.mp4…"
    assemble_titre
    unless titre_final_converted?
      error "Bizarrement, le titre n'a pas pu être converti…"
      raise NotAnError.new("Je dois m'arrêter là.")
    end
  end #/convert_titre_final


  # Assistance pour la définition des opérations
  def define_operations
    require_relative 'assistant/define_operations'
    exec
  end

  # Assistance de l'enregistrement de la capture principale des opérations
  #
  # Attention, cette méthode peut être appelée toute seule
  # Dans ce cas-là, direct est mis à true
  #
  def record_operations
    require_relative('assistant/record_operations')
    exec
  end #/record_operations

  def ask_capture_mov_to_mp4
    clear
    notice "=== “#{name}”, conversion capture.mov -> capture.mp4 ==="
    puts <<-EOT

Dois-je modifier la vitesse de la capture des
opérations, par exemple pour accélérer le fichier
(avant l'enregistrement de la voix) ?

    A:  garder la vitesse originale
    B:  Augmenter la vitesse d'une fois et demi
        (recommandé)
    C:  doubler la vitesse
    D:  Entrer l'accélération (1 = normal,
        2 = doubler, 3 = tripler, et toutes les
        valeurs intermédiaires)

Pour faire des essais, vous pouvez utiliser la
commande :
    vite-faits capture_to_mp4 #{name} speed=<valeur>

    EOT

    speed = nil
    while speed.nil?
      case (getChar("Vitesse choisie :")||'').upcase
      when 'A'
        speed = 1
      when 'B'
        speed = 1.5
      when 'C'
        speed = 2
      when 'D'
        speed = prompt("Accélération à donner :")
        speed || raise(NotAnError.new("Je ne connais pas cette valeur."))
        unless speed.gsub(/0-9\./,'') == ''
          error "La valeur #{speed} n'est pas conforme. On ne devrait\nque des chiffres et le point."
          speed = nil
        end
      else
        raise NotAnError.new("Je ne connais pas cette valeur.")
      end
    end #/while la vitesse n'est pas définie

    # On a la vitesse, on peut convertir
    COMMAND.params.merge!(speed: speed)
    require_module('capture_to_mp4')
    exec_capture_to_mp4
  end #/

  # Méthode qui assiste à l'enregistrement de la voix si
  # nécessaire
  def ask_for_record_voice
    # Il n'est pas sûr que l'utilisateur veuille enregistrer une nouvelle
    # voix
    yesOrStop("Veux-tu procéder à l'enregistrement de la voix pour “#{name}” ?")
    # S'il existe un fichier avec les opérations, on va écrire le texte à
    # l'écran, ou le faire défiler progressivement.
    require_relative('assistant/record_voice')
    exec
  end

  def check_for_reconvert_voice
    mtime_aiff  = File.stat(record_voice_aiff).mtime.to_i
    mtime_mp4   = File.stat(record_voice_path).mtime.to_i

    # Si le fichier mp4 est plus vieux que le fichier aiff, rien à
    # faire. Sinon, ça signifie que le fichier aiff a été modifié après
    # la fabrication du mp4 et qu'il faut donc certainement le refaire.
    mtime_mp4 > mtime_aiff && return # rien à faire

    puts <<-EOT

Le fichier voix AIFF de “#{name}”
a été modifié depuis la production du fichier
voix MP4.

    EOT
    if yesNo("Dois-je reconvertir le fichier .aiff en .mp4 final pour “#{name}” ?")
      require_module('convert_voice_aiff')
      convert_voice_aiff_to_voice_mp4
    end

  end

  # Méthode qui procède à l'assemblage final des éléments
  def proceed_assemblage
    clear
    notice "=== Assemblage de “#{name}” ==="
    puts <<-EOT

Je vais procéder à plusieurs assemblages : celui de la
capture des opérations (capture.mp4) et de la capture
de la voix (voice.mp4).

Puis l'assemblage de tous les éléments entre eux, avec
l'intro, le titre, la « capture » et le final.

Ces opérations sont assez longues, tu peux vaquer à
d'autres occupations en attendant.
    EOT
    sleep 5
    assemble(nomessage = true)

    notice "👍  --> Assemblage complet de “#{name}” effectué avec succès."

    case yesNo("Veux-tu éditer “#{name}” dans Screenflow ?")
    when true
      `open -a Screenflow "#{record_operations_completed}"`
    when NilClass
      raise NotAnError.new
    end

    yesOrStop("Prêt à poursuivre “#{name}” ?")
  end #/proceed_assemblage


  # Assiste à l'upload de la vidéo sur YouTube
  def ask_for_upload_video
    clear
    notice "Tu dois procéder à l'UPLOAD SUR YOUTUBE de “#{name}”."
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
    # Pour s'assurer que l'upload a bien eu lieu, on essaie
    # d'atteindre la vidéo
    if video_sur_youtube?
      notice "J'ai trouvé la vidéo sur YouTube 👍"
      informations.set(uploaded: true)
    else
      raise(NotAnError.new("🚫  Je n'ai pas pu trouver la vidéo sur YouTube, malheureusement…"))
      informations.set(uploaded: false)
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
    File.exists?(record_operations_completed) &&
      video_uploaded? &&
      annonce_FB_deposed? &&
      annonce_facebook_deposed?
  end

  def vignette_finale_existe?(nomessage = true)
    if File.exists?(vignette_path)
      notice "--- La vignette finale existe."
      return true
    else
      return false
    end
  end

  def titre_is_recorded?(nomessage = true)
    vrai = titre_mov && File.exists?(titre_mov)
    if !nomessage && vrai
      notice "--- Titre enregistré."
    end
    return vrai
  end

  def titre_final_converted?(nomessage = true)
    vrai = titre_mov && File.exists?(record_titre_mp4)
    if !nomessage && vrai
      notice "--- Fichier titre final préparé."
    end
    return vrai
  end

  def capture_ts_existe?
    record_operations_path(noalert = true) && File.exists?(record_operations_mp4)
  end

  def video_finale_existe?(nomessage = true)
    existe = File.exists?(record_operations_completed)
    if existe && !nomessage
      notice "--- Tutoriel final assemblé."
    end
    return existe
  end

  def video_uploaded?(nomessage = true)
    vrai = informations.data[:uploaded][:value] === true
    if vrai && !nomessage
      notice "--- Tutoriel uploadé sur YouTube."
    end
    return vrai
  end

  def annonce_facebook_deposed?(nomessage = true)
    vrai = informations.data[:annonce_FB][:value] === true
    if vrai && !nomessage
      notice "--- Annonce Facebook diffusée."
    end
    return vrai
  end

  def annonce_FB_deposed?(nomessage = true)
    vrai = informations.data[:annonce_Scriv][:value] === true
    if vrai && !nomessage
      notice "--- Annonce Forum Scrivener diffusée."
    end
    return vrai
  end

  def youtube_id_defined?(nomessage = true)
    est_defini = informations.data[:youtube_id][:value] != nil
    if est_defini && !nomessage
      notice "--- ID YouTube défini."
    end
    return est_defini
  end

  def infos_existent?
    return true # TODO
  end

end #/ViteFait
