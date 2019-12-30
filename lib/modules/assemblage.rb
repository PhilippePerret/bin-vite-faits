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
    # en version .ts). Note : ils peuvent appartenir à d'autres séries
    # de tutoriels que les vite-faits.
    self.class.prepare_assemblage

    # On s'assure que les fichiers du tutoriel soient prêts (titre et
    # capture des opérations, en ts)
    prepare_assemblage

    # Si un fichier final existe, on produit une nouvelle version
    # de façon silencieuse et systématique.
    make_new_version_complete if File.exists?(record_operations_completed)

    cmd = "ffmpeg -i \"concat:#{intro_ts}|#{titre_ts}|#{record_operations_ts}|#{final_ts}\" -c:a copy -bsf:a aac_adtstoasc \"#{record_operations_completed}\""
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"
    if COMMAND.options[:verbose] && !nomessage
      puts "\n---- Commande finale : '#{cmd}'"
    else
      notice "📦  Assemblage final, merci de patienter…"
    end
    res = `#{cmd}`

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
    voice_capture_exists?(true) || raise("Le fichier voix est introuvable")
    # Le fichier contenant le titre du tutoriel
    (titre_mov && File.exists?(titre_mov)) || raise("Le titre doit être enregistré, pour procéder à l'assemblage.\nUtiliser la commande `vite-faits assistant #{name} pour=titre` pour l'ouvrir et l'enregistrer.")
  rescue Exception => e
    raise NotAnError.new(e.message)
  end

  def prepare_assemblage
    if COMMAND.options[:force]
      unlink_if_exist([record_operations_ts, titre_mp4, titre_ts])
    end
    prepare_source  unless source_prepared?
    prepare_titre   unless titre_prepared?
  end

  def prepare_source
    File.exists?(record_operations_mp4) || capture_to_mp4
    self.class.make_ts_file( record_operations_mp4, record_operations_ts )
  end
  def prepare_titre
    File.exists?(titre_mp4) || assemble_titre
    self.class.make_ts_file(titre_mp4, titre_ts)
  end

  def source_prepared?
    File.exists?(record_operations_ts)
  end

  def titre_prepared?
    File.exists?(titre_ts)
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
    FileUtils.move(record_operations_completed, version_path)
    if File.exists?(version_path)
      notice "Version #{name}_v-#{version}.mp4 produite avec succès 👍"
      notice "(mais la dernière est toujours la '#{name}_completed.mp4')"
    else
      raise NotAnError.new("Le fichier version (*) devrait exister…\n(*) #{version_path}")
    end
    if File.exists?(record_operations_completed)
      raise NotAnError.new("Le fichier completed (*) ne devrait plus exister…\n(*) #{record_operations_completed}")
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
      notice "---> Production de #{relative_pathof(dst)} 👍"
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
