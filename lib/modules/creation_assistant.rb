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
en place à la diffusion et l'annonce.
Note : on peut aussi reprendre la création là où on s'est
arrêté.
    EOT

    # On demande le nom
    tuto = nil
    tuto_name = ask_for_tuto_name || return

    # On crée une instance, le traitement sera plus facile ensuite
    tuto = new(tuto_name)

    if tuto.exists?
      ask_when_exists_or_completed(tuto)
    else
      create_new_tutorial(tuto)
    end

    tuto.set_generales_informations   unless tuto.infos_defined?(false)
    tuto.record_titre                 unless tuto.titre_is_recorded?(false)
    tuto.convert_titre_final          unless tuto.titre_final_converted?(false)
    tuto.build_vignette_jpeg          unless tuto.vignette_finale_existe?(false)

    tuto.define_operations            unless tuto.operations_are_defined?(false,false)
    # Enregistrement des opérations
    tuto.record_operations            unless tuto.operations_are_recorded?(false,false)

    # On finalise le fichier capture, pour qu'il corresponde à ce dont
    # on a besoin pour enregistrer la voix. Notamment au niveau de la
    # vitesse de la vidéo
    tuto.ask_capture_mov_to_mp4       unless tuto.mp4_capture_exists?(false,false)

    # Enregistrement de la voix
    tuto.ask_for_record_voice         unless tuto.voice_capture_exists?(false,false)

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
    notice "\n\nOK, on s'arrête là."
    unless tuto.nil?
      notice "Tu pourras reprendre n'importe quand on tapant à nouveau le nom du dossier '#{tuto.name}'"
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

  def set_generales_informations
    yesNo("Prêt à définir les informations générales ?") || return
    require_relative 'assistant/generales_informations'
    exec
  end

  def record_titre
    yesNo("Prêt pour enregistrer le titre animé ?") || return
    require_relative 'assistant/record_titre'
    exec
  end

  def build_vignette_jpeg
    yesNo("Prêt pour fabriquer la vignette ?") || return
    require_relative 'assistant/build_vignette_jpeg'
    exec
  end


  # --- LES SOUS-MÉTHODES D'ASSISTANCE ---


  # Convertir le titre final
  def convert_titre_final
    notice "* Conversion du titre.mov en titre.mp4…"
    titre_to_mp4
    if titre_final_converted?
      notice "Titre converti en fichier .mp4 👍"
    else
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
    notice "=== Conversion capture.mov -> capture.mp4 ==="
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
    while speed.nil
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
    yesNo("Veux-tu procéder à l'enregistrement de la voix ?") || return
    # S'il existe un fichier avec les opérations, on va écrire le texte à
    # l'écran, ou le faire défiler progressivement.
    require_relative('assistant/record_voice')
    exec
  end

  # Méthode qui procède à l'assemblage final des éléments
  def proceed_assemblage
    clear
    notice "=== Assemblage ==="
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

    notice "👍  --> Assemblage complet effectué avec succès."

    if yesNo("Veux-tu l'éditer dans Screenflow ?")
      `open -a Screenflow "#{completed_path}"`
    end

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
    unless video_uploaded?
      informations.set(uploaded: true)
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
    vrai = titre_mov && File.exists?(titre_mp4)
    if !nomessage && vrai
      notice "--- Fichier titre final préparé."
    end
    return vrai
  end

  def capture_ts_existe?
    src_path(noalert = true) && File.exists?(mp4_path)
  end

  def video_finale_existe?(nomessage = true)
    existe = File.exists?(completed_path)
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

  # Raccourci
  def yesOrStop(question); self.class.yesOrStop(question) end

end #/ViteFait
