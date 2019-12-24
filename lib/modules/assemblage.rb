# encoding: UTF-8
class ViteFait

  # Assemble
  def exec_assemble nomessage = false

    # Avant toute chose, on doit s'assurer qu'il existe les fichiers
    # minimum pour procéder à l'opération
    required_files_exists? # raise en cas d'erreur

    # On procède d'abord à l'assemblage de la capture des opérations
    # et la capture de la voix
    require_module('assemblage_capture')
    exec_assemble_capture

    # On s'assure que les fichiers communs soient prêts (intro et final,
    # en version .ts)
    self.class.prepare_assemblage

    # On s'assure que les fichiers du tutoriel soient prêts (titre et
    # capture des opérations, en ts)
    prepare_assemblage

    # Le fichier final doit être détruit s'il existe
    File.unlink(completed_path) if File.exists?(completed_path)
    cmd = "ffmpeg -i \"concat:#{intro_ts}|#{titre_ts}|#{ts_path}|#{final_ts}\" -c:a copy -bsf:a aac_adtstoasc \"#{completed_path}\""
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"
    if COMMAND.options[:verbose] && !nomessage
      puts "\n---- Commande finale : '#{cmd}'"
    else
      notice "📦  Assemblage final, merci de patienter…"
    end
    res = `#{cmd}`

    # Message de fin (si on n'est pas avec l'assistant)
    unless nomessage
      Command.clear_terminal
      notice <<-EOT
=== Assemblage effectué avec succès ===

Avant d'uploader la vidéo, créer sa vignette en jouant :

    vite-fait open_vignette #{name}

Puis uploader la vidéo en jouant :

    vite-faits upload #{name}

Récupérer l'identifiant YouTube et l'enregistrer avec :

    vite-faits infos #{name} youtube_id="<youtube id>"

S'assurer qu'il y a un titre, un titre anglais et une description ou jouer :

    vite-faits infos #{name} titre="…" titre_en="…" description="…"

Annoncer le nouveau tutoriel sur Facebook et le forum Scrivener :

    vite-faits annonce #{name} pour=fb
    vite-faits annonce #{name} pour=scriv
    # Ou pour les deux en même temps :
    vite-faits annonces #{name}

Et enfin, mettez le dossier de côté (sur le dique) à l'aide de :

    vite-faits move #{name} vers=published
    # Ou, si pas d'annonce :
    vite-faits move #{name} vers=completed

      EOT
    end #/si pas de no message

  end


  def required_files_exists?
    # Le fichier capture des opérations, bien entendu
    src_path || raise("Le fichier capture des opérations est introuvable")
    # Le fichier capture de la voix
    voice_capture_exists?(true) || raise("Le fichier voix est introuvable")
    # Le fichier contenant le titre du tutoriel
    (titre_mov && File.exists?(titre_mov)) || raise("Le titre doit être enregistré, pour procéder à l'assemblage.\nUtiliser la commande `vite-faits assistant #{name} pour=titre` pour l'ouvrir et l'enregistrer.")
  rescue Exception => e
    raise NotAnError.new(e.message)
  end

  def prepare_assemblage
    if COMMAND.options[:force]
      unlink_if_exist([ts_path, titre_mp4, titre_ts])
    end
    prepare_source  unless source_prepared?
    prepare_titre   unless titre_prepared?
  end

  def prepare_source
    File.exists?(mp4_path) || capture_to_mp4
    self.class.make_ts_file( mp4_path, ts_path )
  end
  def prepare_titre
    File.exists?(titre_mp4) || assemble_titre
    self.class.make_ts_file(titre_mp4, titre_ts)
  end

  def source_prepared?
    File.exists?(ts_path)
  end

  def titre_prepared?
    File.exists?(titre_ts)
  end

  def intro_ts
    @intro_ts ||= self.class.intro_ts
  end
  def final_ts
    @final_ts ||= self.class.final_ts
  end

  # ---------------------------------------------------------------------
  #   CLASSE
  # ---------------------------------------------------------------------

  class << self

    def check_files_assemblage
      unless File.exists?(intro_mp4)
        raise("Le fichier MP4 de l'intro est introuvable (#{intro_mp4}).")
      end
      unless File.exists?(final_mp4)
        raise("Le fichier MP4 du final est introuvable (#{final_mp4}).")
      end
      unless File.exists?(machine_a_ecrire_path)
        raise("Le fichier son de la machine à écrire est introuvable (#{machine_a_ecrire_path}).")
      end
    end


    def prepare_intro
      make_ts_file( intro_mp4, intro_ts )
    end

    def prepare_final
      make_ts_file( final_mp4, final_ts )
    end

    def make_ts_file src, dst
      cmd = "ffmpeg -i \"#{src}\" -c copy -bsf:v h264_mp4toannexb -f mpegts \"#{dst}\""
      COMMAND.options[:verbose] || cmd << " 2> /dev/null"
      res = `#{cmd}`
      notice "---> Production de #{dst} 👍"
    end

    def intro_prepared?
      File.exists?(intro_ts)
    end
    def final_prepared?
      File.exists?(final_ts)
    end

    def intro_ts
      @intro_ts ||= File.join(VITEFAIT_MATERIEL_FOLDER,"#{intro_affixe}.ts")
    end
    def intro_mp4
      @intro_mp4 ||= File.join(VITEFAIT_MATERIEL_FOLDER,"#{intro_affixe}.mp4")
    end
    def final_ts
      @final_ts ||= File.join(VITEFAIT_MATERIEL_FOLDER,"#{final_affixe}.ts")
    end
    def final_mp4
      @final_mp4 ||= File.join(VITEFAIT_MATERIEL_FOLDER,"#{final_affixe}.mp4")
    end
    def intro_affixe
      @intro_affixe ||= "INTRO-vite-faits-sonore"
    end
    def final_affixe
      @final_affixe ||= "FINAL-vite-faits-sonore"
    end

    def prepare_assemblage
      check_files_assemblage
      intro_prepared? || prepare_intro
      final_prepared? || prepare_final

    rescue Exception => e
      error e.message
      error "🖐  Impossible de procéder à l'assemblage."
    end

  end#/<< self
end#/ViteFait
