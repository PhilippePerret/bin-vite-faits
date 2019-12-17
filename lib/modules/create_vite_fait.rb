# encoding: UTF-8
class ViteFait

  def exec_create
    if exists? && !(COMMAND.options[:force] || COMMAND.options[:lack])
      error "Ce projet existe déjà, je ne peux pas le créer."
      error "Pour le reconstruire complètement, ajouter l'option -f/--force."
      error "Pour actualiser son contenu (ajouter les fichiers manquant), ajouter -l/--lack."
    else

      puts "\n\n"

      if exists? && COMMAND.options[:force]
        FileUtils.rm_rf(work_folder_path)
      end

      # Création des dossiers
      mkdirs_if_not_exist([work_folder_path, exports_folder, titre_folder, vignette_folder])

      # Copie du fichier scrivener pour la capture des opérations
      unless File.exists?(scriv_file_path) # options --lack
        src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Vite-Faits.scriv')
        FileUtils.copy_entry(src, scriv_file_path)
        src_x = File.join(scriv_file_path,'Vite-Faits.scrivx')
        dst_x = File.join(scriv_file_path, "#{name}.scrivx")
        FileUtils.move(src_x, dst_x)
        notice "--> Scrivener : #{scriv_file_path} 👍"
      end

      # Copie du fichier Scrivener pour le titre
      unless File.exists?(titre_path) # options --lack
        src = File.join(VITEFAIT_MATERIEL_FOLDER,'Titre.scriv')
        FileUtils.copy_entry(src, titre_path)
        notice "--> TITRAGE : #{titre_path} 👍"
      end

      # Copie du fichier Gimp pour la vignette
      unless File.exists?(vignette_gimp)
        src = File.join(VITEFAIT_MATERIEL_FOLDER,'Vignette.xcf')
        FileUtils.copy(src, vignette_gimp)
        notice "--> VIGNETTE : #{vignette_gimp} 👍"
      end

      # Copie du gabarit Screenflow
      unless File.exists?(screenflow_path)
        src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel','gabarit.screenflow')
        FileUtils.copy_entry(src, screenflow_path)
        notice "---> Screenflow : #{screenflow_path} 👍"
      end

      notice (if COMMAND.options[:lack]
        "\n👍  Dossier vite-fait actualisé avec succès"
      elsif COMMAND.options[:force]
        "\n👍  Dossier vite-fait reconstruit avec succès"
      else
        "\n👍  Nouveau vite-fait créé avec succès"
      end)
      `open -a Finder "#{work_folder_path}"`
    end

  end
end #/ViteFait
