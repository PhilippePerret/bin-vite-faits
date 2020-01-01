# encoding: UTF-8
class ViteFait

  def exec_create(nomessage = false)
    if nomessage
      COMMAND.options.merge!(silence: true)
    end

    # Si le tutoriel n'existe pas, on met tout de suite son lieu, pour
    # savoir où le créer.
    unless exists?
      reset
      @lieu = :chantier
    end

    if exists? && !(COMMAND.options[:force] || COMMAND.options[:lack])
      error "Ce projet existe déjà, je ne peux pas le créer."
      error "Pour le reconstruire complètement, ajouter l'option -f/--force."
      error "Pour actualiser son contenu (ajouter les fichiers manquant), ajouter -l/--lack."
    else
      COMMAND.options[:silence] || puts("\n\n")

      if exists? && COMMAND.options[:force]
        FileUtils.rm_rf(chantier_folder_path)
      end

      puts "MEC, JE VAIS TESTER LE NOM '#{name}'"
      require_module('tutoriel/name')
      ViteFait.is_valid_name?(name) || return

      puts "LE NOM EST VALIDE, MEC"

      # Création des dossiers
      mkdirs_if_not_exist([chantier_folder_path, exports_folder, titre_folder, assets_folder, operations_folder, vignette_folder, voice_folder])

      # Copie du fichier scrivener pour la capture des opérations
      unless File.exists?(scriv_file_path) # options --lack
        src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Vite-Faits.scriv')
        ViteFait.scrivener_copy(src,scriv_file_path)
        notice "--> Scrivener : #{scriv_file_name} 👍"
      end

      # Copie du fichier Scrivener pour le titre
      unless File.exists?(titre_path) # options --lack
        src = File.join(VITEFAIT_MATERIEL_FOLDER,'Titre.scriv')
        FileUtils.copy_entry(src, titre_path)
        notice "--> TITRAGE : ./Titre/Titre.scriv 👍"
      end

      # Copie du fichier Gimp pour la vignette
      unless File.exists?(vignette_gimp)
        src = File.join(VITEFAIT_MATERIEL_FOLDER,'Vignette.xcf')
        FileUtils.copy(src, vignette_gimp)
        notice "--> VIGNETTE : ./Vignette/Vignette.xcf 👍"
      end

      # Le dossier final qu'il faudra ouvrir.
      # Car l'utilisateur veut peut-être créer un fichier en attente
      final_folder = chantier_folder_path

      notice (if COMMAND.options[:lack]
        "\n👍  Dossier vite-fait actualisé avec succès"
      elsif COMMAND.options[:force]
        "\n👍  Dossier vite-fait reconstruit avec succès"
      else
        # Si l'option type est mise à 'attente' ou 'en_attente' ou 'waiting',
        # on déplace le dossier créé
        lieu = ''
        if COMMAND.params[:type] == 'en_attente'
          lieu = " dans le dossier des tutoriels en attente"
          FileUtils.move(chantier_folder_path, attente_folder_path)
          final_folder = attente_folder_path
        end
        "\n👍  Nouveau vite-fait créé avec succès#{lieu}"
      end)

      # On ouvre le dossier et on revient dans le terminal
      `open -a Finder "#{final_folder}"`
      `open -a Terminal`
      puts "\n\n"
    end

  end #/exec_create

end #/ViteFait
