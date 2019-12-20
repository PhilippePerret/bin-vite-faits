# encoding: UTF-8
=begin

  Module pour écrire dans le Terminal le rapport complet sur le tutoriel
  désigné.

  TODO ajouter toutes les informations
    - versions existantes (aka dossiers)

=end
class ViteFait

  def exec_print_report
    # TODO Poursuivre

    unless valid?
      error "Désolé, mais ce tutoriel doit être fixé."
      return
    end

    clear
    puts "=== INFORMATION SUR UN TUTORIEL ===\n\n"
      puts "Nom du dossier   : #{name}"
    if exists?
      puts "Titre            : #{titre || '---'}"
      puts "Titre anglais    : #{titre_en || '---'}"
      puts "Description      : #{description || '---'}"
      puts "Lieu actuel      : #{lieu} — #{hlieu}"
      puts "YoutTube ID      : #{youtube_id || '---'}"
      if informations[:annonce_FB]
        notice "Annonce Facebook : oui"
      else
        error "Annonce Facebook : non"
      end
      if informations[:annonce_Scriv]
        notice "Annonce Lat&Lit  : oui"
      else
        error "Annonce Lat&Lit  : non"
      end
    else
      puts "Lieu actuel    : aucun — le dossier n'est pas créé"
    end
    if vitefait.defined?
      if vitefait.exists?
        puts "\nFichiers de travail"
        puts "-------------------\n"
        line_exists_file(informations.path, 'Informations')
        line_exists_file(operations_path, 'Opérations')
        line_exists_file(scriv_file_path, 'Scrivener')
        line_exists_file(src_path, 'source MOV')
        line_exists_file(titre_path, 'Titre (Scrivener)')
        line_exists_file(titre_mov, 'Titre (capture)')
        line_exists_file(vignette_gimp, 'Vignette Gimp')
        line_exists_file(vocal_capture_path, 'Voix')
        line_exists_file(screenflow_path, 'ScreenFlow')
        line_exists_file(premiere_path, 'Adobe Premiere')

        # fichier informations
        # fichier voice
        # fichier operations
        puts "\nFichiers finaux"
        puts "---------------\n"
        line_exists_file(completed_path, 'VIDÉO FINALE')
        line_exists_file(vignette_path, 'Vignette JPEG')
        line_exists_file(mp4_path, 'Capture (mp4)')
        line_exists_file(titre_mp4, "Titre (mp4)")
        line_exists_file(voice_aac, 'Voix finale')
      else
        if COMMAND.options[:check]
          error "Le dossier travail vite-fait '#{vitefait.chantier_folder_path}' n'existe pas."
          if vitefait.folder_completed?
            notice "Mais il existe en tant que dossier fini sur le disque."
          elsif vitefait.en_chantier_on_disk?
            notice "Mais il existe en tant que dossier en chantier sur le disque. Pour le mettre en dossier de travail sur l'ordinateur, utiliser la commande `./bin/vitefait.rb work #{vitefait.name}`"
          elsif vitefait.folder_en_attente?
            notice "Mais il existe en tant que dossier en projet sur le disque. Pour le mettre en dossier de travail sur l'ordinateur, utiliser la commande `./bin/vitefait.rb work #{vitefait.name}`"
          end
        end
      end
    end
    puts "\n\n\n"
  end #/exec_print_report

end
