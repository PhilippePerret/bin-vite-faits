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
    puts "\n\n\n"

    if vitefait.defined?
      if vitefait.exists?
        notice "Dossier travail vite-fait : '#{vitefait.work_folder}'."
        line_exists_file(screenflow_path, 'ScreenFlow')
        line_exists_file(scriv_file_path, 'Scrivener')
        line_exists_file(src_path, 'source')
        line_exists_file(mp4_path, 'capture.mp4')
        line_exists_file(ts_path, 'capture.ts')
        line_exists_file(completed_path, 'VIDÉO FINALE')
      else
        if COMMAND.options[:check]
          error "Le dossier travail vite-fait '#{vitefait.work_folder_path}' n'existe pas."
          if vitefait.completed?
            notice "Mais il existe en tant que dossier fini sur le disque."
          elsif vitefait.work_folder_on_disk_exists?
            notice "Mais il existe en tant que dossier en chantier sur le disque. Pour le mettre en dossier de travail sur l'ordinateur, utiliser la commande `./bin/vitefait.rb work #{vitefait.name}`"
          elsif vitefait.waiting_folder_exists?
            notice "Mais il existe en tant que dossier en projet sur le disque. Pour le mettre en dossier de travail sur l'ordinateur, utiliser la commande `./bin/vitefait.rb work #{vitefait.name}`"
          end
        end
      end
    end
    puts "\n\n\n"
  end #/exec_print_report

end
