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

    tuto.set_generales_informations   unless tuto.infos_defined?
    tuto.record_titre                 unless tuto.titre_is_recorded?
    tuto.convert_titre_final          unless tuto.titre_final_converted?
    tuto.build_vignette_jpeg          unless tuto.vignette_finale_existe?

    tuto.define_operations            unless tuto.file_operations_exists?
    tuto.record_operations            unless tuto.operations_are_recorded?

    return

    tuto.assiste_creation

    notice "\nTerminé !"

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

  def assiste_creation

    ask_for_record_voice    unless voice_capture_exists?

    proceed_assemblage      unless video_finale_existe?

    ask_for_upload_video    unless video_uploaded?
    ask_for_youtube_id      unless youtube_id_defined?

    ask_for_annonce_facebook  unless annonce_facebook_deposed?
    ask_for_annonce_scrivener unless annonce_FB_deposed?

    finale_message

  end #/ assistant de l'instance

  # --- LES SOUS-MÉTHODES D'ASSISTANCE ---


  # Convertir le titre final
  def convert_titre_final
    notice "* Conversion du titre.mov en titre.mp4…"
    titre_to_mp4
    if titre_final_converted?
      notice "Titre converti en fichier .mp4 👍"
    else
      error "Bizarrement, le titre n'a pas pu être converti…"
      raise NotAError.new("Je dois m'arrêter là.")
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

  def vignette_finale_existe?
    File.exists?(vignette_path)
  end

  def titre_is_recorded?
    titre_mov && File.exists?(titre_mov)
  end

  def titre_final_converted?
    titre_mov && File.exists?(titre_mp4)
  end

  def operations_are_recorded?
    src_path(noalert = true) && File.exists?(src_path)
  end

  def capture_ts_existe?
    src_path(noalert = true) && File.exists?(mp4_path)
  end

  def video_finale_existe?
    File.exists?(completed_path)
  end

  def video_uploaded?
    informations.data[:uploaded]
  end

  def annonce_facebook_deposed?
    informations.data[:annonce_facebook]
  end

  def annonce_FB_deposed?
    informations.data[:annonce_scrivener]
  end

  def youtube_id_defined?
    informations.data[:youtube_id]
  end

  def infos_existent?
    return true # TODO
  end

  # Raccourci
  def yesOrStop(question); self.class.yesOrStop(question) end

end #/ViteFait
