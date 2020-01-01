# encoding: UTF-8
=begin

  Module pour écrire dans le Terminal le rapport complet sur le tutoriel
  désigné.

  TODO ajouter toutes les informations
    - versions existantes (aka dossiers)

=end
class ViteFait
  RAPPORT_LABELS_LEN = 22

  # Pour construire et écrire une ligne avec des labels d'une
  # certaine longueur
  def puts_line(label, value)
    puts "#{label.ljust(RAPPORT_LABELS_LEN,'.')} #{value}"
  end
  def exec_print_report
    unless valid?
      error "Désolé, mais ce tutoriel doit être réparé."
      return
    end
    require_module('every/durees')

    clear
    puts "=== INFORMATION SUR UN TUTORIEL ===\n\n"
    puts_line('Nom du dossier', name)
    if exists?
      puts_line('Titre',titre || '---')
      puts_line('Titre anglais', titre_en || '---')
      puts_line('Description', description || '---')
      puts_line('Lieu actuel', hlieu)
      puts_line('Vrai Vite-Fait', has_own_intro? ? 'non' : 'oui')
      write_last_step_conception
      puts_line(htype_duration, tutoriel_hduration)
      puts_line('YoutTube ID', youtube_id || '---')
      fb_OK = informations[:annonce_FB] === true
      color = fb_OK ? '32' : '31'
      puts_line('Annonce Facebook', "\033[1;#{color}m#{fb_OK ? 'oui' : 'non'}\033[0m")
      sc_OK =  informations[:annonce_Scriv] === true
      color = sc_OK ? '32' : '31'
      puts_line('Annonce Scrivener', "\033[1;#{color}m#{sc_OK ? 'oui' : 'non'}\033[0m")
    else
      puts_line('Lieu actuel', "aucun — le dossier n'est pas créé")
    end
    if self.defined?
      if self.exists?
        puts "\n\nFichiers de travail"
        puts "-------------------\n"
        line_exists_file(informations.path, 'Informations')
        line_exists_file(operations_path, 'Opérations')
        line_exists_file(scriv_file_path, 'Scrivener')
        line_exists_file(record_operations_path(noalert=true), 'source MOV')
        line_exists_file(titre_path, 'Titre (Scrivener)')
        line_exists_file(titre_mov, 'Titre (capture)')
        line_exists_file(vignette_gimp, 'Vignette Gimp')
        line_exists_file(record_voice_path, 'Voix')
        line_exists_file(screenflow_path, 'ScreenFlow')
        line_exists_file(premiere_path, 'Adobe Premiere')
        line_exists_file(own_intro_mp4, 'INTRO propre')
        line_exists_file(own_final_mp4, 'FINAL propre')

        # fichier informations
        # fichier voice
        # fichier operations
        puts "\nFichiers finaux"
        puts "---------------\n"
        line_exists_file(final_tutoriel_mp4, 'VIDÉO FINALE')
        line_exists_file(vignette_path, 'Vignette JPEG')
        line_exists_file(record_operations_mp4, 'Capture (mp4)')
        line_exists_file(record_titre_mp4, "Titre (mp4)")
        line_exists_file(record_voice_aac, 'Voix finale')

        puts "\n\nTâches restant à faire"
        puts "----------------------\n"
        puts lines_taches

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

  def write_last_step_conception
    require_module('tutoriel/conception')
    # On en profite pour définir la donnée logic_step si elle
    # n'est pas définie.
    informations[:logic_step] || conception.save_last_logic_step
    # en_chantier? || return
    laststep = conception.last_logic_step
    puts_line('Étape conception', "#{laststep.index}. #{laststep.hname}")
  end

  # Retourne les tâches restant à accomplir
  def lines_taches
    require_module('tools/taches')
    taches.listing.collect do |tache|
      tache.display(format: :simple)
    end
  end

end
