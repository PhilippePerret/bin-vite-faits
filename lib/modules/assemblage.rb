# encoding: UTF-8
class ViteFait
  class << self

    def prepare_assemblage
      check_files_assemblage
      intro_prepared? || prepare_intro
      final_prepared? || prepare_final

    rescue Exception => e
      error e.message
      error "🖐  Impossible de procéder à l'assemblage."
    end

  end # / << self

  def exec_assemble

    # On s'assure que les fichiers communs soient prêts (intro et final,
    # en version .ts)
    self.class.prepare_assemblage

    # On s'assure que les fichiers du tutoriel soient prêts (titre et
    # capture des opérations, en ts)
    prepare_assemblage

    # On doit vérifier si on possède bien les fichiers indispensables
    check_files_assemblage

    # Le fichier final doit être détruit s'il existe
    File.unlink(completed_path) if File.exists?(completed_path)
    cmd = "ffmpeg -i \"concat:#{intro_ts}|#{titre_ts}|#{ts_path}|#{final_ts}\" -c:a copy -bsf:a aac_adtstoasc \"#{completed_path}\""
    # cmd = "ffmpeg -i \"concat:#{intro_ts}|#{titre_ts}\" -c:a copy -bsf:a aac_adtstoasc \"#{completed_path}\""
    # cmd = "ffmpeg -i \"concat:#{intro_ts}|#{titre_ts}\" -codec copy -bsf:a aac_adtstoasc \"#{completed_path}\""
    puts "\n---- Commande finale : '#{cmd}'"
    res = `#{cmd}`


  end

  def prepare_assemblage
    if COMMAND.options[:force]
      unlink_if_exist([ts_path, titre_mp4, titre_ts])
    end
    source_prepared? || prepare_source
    titre_prepared? ||  prepare_titre
  end

  def check_files_assemblage
    unless File.exists?(src_path) || File.exists?(mp4_path)
      raise("Aucun fichier source n'a été trouvé (#{src_path} ou #{mp4_path}). Il faut le créer.")
    end
    unless File.exists?(titre_path)
      raise("Aucun fichier de titre n'a été trouvé (#{titre_path}). Il faut le créer.")
    end
  end

  def prepare_source
    self.class.make_ts_file( mp4_path, ts_path )
  end
  def prepare_titre
    puts "-> prepare_titre"
    File.exists?(titre_mp4) || titre_to_mp4
    self.class.make_ts_file(titre_mp4, titre_ts)
    puts "<- prepare_titre"
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
      notice "---> Production de #{dst} 👍"
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

  end#/<< self
end#/ViteFait
