# encoding: UTF-8
class ViteFait

  # Assemble
  def exec_assemble nomessage = false

    # Avant toute chose, on doit s'assurer qu'il existe les fichiers
    # minimum pour procéder à l'opération
    required_files_exists? # raise en cas d'erreur

    # Si l'opération est forcée, on doit refaire tous les fichiers
    if COMMAND.options[:force]
      unlink_if_exist([record_operations_ts, record_titre_mp4, record_titre_ts])
    end

    # On s'assure que les fichiers communs soient prêts (intro et final,
    # en version .ts). Note : ils peuvent appartenir à d'autres séries
    # de tutoriels que les vite-faits.
    self.class.prepare_assemblage

    # On procède d'abord à l'assemblage des opérations
    # et de la voix, sauf si le fichier capture existe et que l'option
    # --force n'est pas invoquée
    unless source_prepared?
      require_module('assemblage_capture')
      exec_assemble_capture # => capture.mp4
      prepare_source # => capture.ts
    else
      notice "Fichier #{name}/Operations/capture.ts déjà prêt"
    end

    # On s'assure que les fichiers du tutoriel soient prêts (titre et
    # capture des opérations, en ts)
    unless titre_prepared?
      prepare_titre
    end

    # Si un fichier final existe, on produit une nouvelle version
    # de façon silencieuse et systématique.
    make_new_version_complete if File.exists?(final_tutoriel_mp4)

    # cmd = "ffmpeg -i \"concat:#{self.class.intro_ts}|#{record_titre_ts}|#{record_operations_ts}|#{self.class.final_ts}\" -c:a copy -bsf:a aac_adtstoasc \"#{final_tutoriel_mp4}\""
    # cmd = "ffmpeg -i \"concat:#{self.class.intro_ts}|#{record_titre_ts}|#{record_operations_ts}|#{self.class.final_ts}\" -c:a copy \"#{final_tutoriel_mp4}\""
    # cmd = "ffmpeg -fflags +igndts -i \"concat:#{self.class.intro_ts}|#{record_titre_ts}|#{record_operations_ts}|#{self.class.final_ts}\" -c:a copy \"#{final_tutoriel_mp4}\""
    cmd = "ffmpeg -fflags +igndts -i \"concat:#{self.class.intro_ts}|#{record_titre_ts}|#{record_operations_ts}|#{self.class.final_ts}\" -c:a copy -copytb 1 \"#{final_tutoriel_mp4}\""
    # À essayer :
    # cmd = "ffmpeg -i \"concat:#{self.class.intro_ts}|#{record_titre_ts}|#{record_operations_ts}|#{self.class.final_ts}\" -c:a copy -copytb 1 \"#{final_tutoriel_mp4}\""
    # Ne fonctionne pas :
    # cmd = "ffmpeg -fflags +igndts -i \"concat:#{self.class.intro_ts}|#{record_titre_ts}|#{record_operations_ts}|#{self.class.final_ts}\" -c:v copy -c:a copy \"#{final_tutoriel_mp4}\""
    # cmd = "ffmpeg -fflags +igndts -i \"concat:#{self.class.intro_ts}|#{record_titre_ts}|#{record_operations_ts}|#{self.class.final_ts}\" -map 0:0 -map 0:1 -c:v copy -c:a copy \"#{final_tutoriel_mp4}\""
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"
    if COMMAND.options[:verbose] && !nomessage
      puts "\n---- Commande finale : '#{cmd}'"
    else
      notice "📦  Assemblage final, merci de patienter…"
    end
    start_time = Time.now.to_i
    res = `#{cmd}`
    end_time = Time.now.to_i

    if end_time < start_time + 10
      # <= Le temps de travail est trop court
      # => Un problème est survenu
      error "Un problème est survenu avec la commande FFMPEG (*). Je m'arrête là."
      error "--- Commande : #{cmd}"
      return
    end

    # Message de fin (si on n'est pas avec l'assistant)
    unless nomessage
      clear
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

    save_last_logic_step

  end


  def required_files_exists?
    # Le fichier capture des opérations, bien entendu
    record_operations_path || raise("Le fichier capture des opérations est introuvable")
    # Le fichier capture de la voix
    unless voice_capture_exists?
      if File.exists?(record_voice_aiff)
        require_module('voice/convert_voice_aiff')
        convert_voice_aiff_to_voice_mp4
      end
    end
    voice_capture_exists?(true) || raise
    # Le fichier contenant le titre du tutoriel
    (titre_mov && File.exists?(titre_mov)) || raise("Le titre doit être enregistré, pour procéder à l'assemblage.\nUtiliser la commande `vite-faits assistant #{name} pour=titre` pour l'ouvrir et l'enregistrer.")
  rescue Exception => e
    raise NotAnError.new(e.message)
  end

  def prepare_source
    File.exists?(record_operations_mp4) || capture_to_mp4
    self.class.make_ts_file( record_operations_mp4, record_operations_ts )
  end
  def prepare_titre
    File.exists?(record_titre_mp4) || assemble_titre
    self.class.make_ts_file(record_titre_mp4, record_titre_ts)
  end

  def source_prepared?
    File.exists?(record_operations_ts)
  end

  def titre_prepared?
    File.exists?(record_titre_ts)
  end

  # Méthode qui produit une nouvelle version de la vidéo complète
  def make_new_version_complete
    version_path  = nil
    version       = nil
    (0..199).each do |ivers|
      iversion = 200 - ivers
      version = iversion.to_s.rjust(3,'0')
      version_path = File.join(exports_folder, "#{name}_v-#{version}.mp4")
      File.exists?(version_path) || break
    end
    FileUtils.move(final_tutoriel_mp4, version_path)
    if File.exists?(version_path)
      notice "Version #{name}_v-#{version}.mp4 produite avec succès 👍"
      notice "(mais la dernière est toujours la '#{name}_completed.mp4')"
    else
      raise NotAnError.new("Le fichier version (*) devrait exister…\n(*) #{version_path}")
    end
    if File.exists?(final_tutoriel_mp4)
      raise NotAnError.new("Le fichier completed (*) ne devrait plus exister…\n(*) #{final_tutoriel_mp4}")
    end
    return true
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
      unless File.exists?(machine_a_ecrire_aac)
        raise("Le fichier son de la machine à écrire est introuvable (#{machine_a_ecrire_aac}).")
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
      relpath = vitefait.relative_pathof(dst)
      relpath != dst || (relpath = File.basename(dst))
      notice "---> Production de #{relpath} 👍"
    end

    def intro_prepared?
      File.exists?(intro_ts)
    end
    def final_prepared?
      File.exists?(final_ts)
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
