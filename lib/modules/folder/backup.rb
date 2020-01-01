# encoding: UTF-8
class ViteFait
  # Exécute un backup du tutoriel sur le dossier spécifié
  def exec_backup
    # Le dossier backup doit exister
    IO.check_existence(VITEFAIT_BACKUP_FOLDER,{interactive:false}) || return
    clear
    notice <<-EOT
=== Production d'un backup de #{name} ===

Je vais procéder à une copie de sauvegarde du projet
“#{titre||name}” sur le disque de
backup défini dans le fichier de configuration :

#{VITEFAIT_BACKUP_FOLDER}

    EOT

    yesNo("Procéder à cette opération ?") || return
    proceed_backup
  end

  # On procède vraiment au backup du dossier du tutoriel
  def proceed_backup
    notice_prov "* Backup de '#{name}'. L'opération peut être plus ou moins longue…"
    remove_folder_backup_if_exists
    FileUtils.copy_entry(current_folder, backup_folder)
    IO.check_existence(backup_folder, {interactive:true}) || return
    notice "Backup de “#{name}” effectué avec succès ! #{String::POUCE}"
  end

  def remove_folder_backup_if_exists
    FileUtils.rm_rf(backup_folder) if File.exists?(backup_folder)
  end


  class << self

    # Actualise tous les backups qui sont "out-of-date"
    # (et seulement ceux-là)
    def proceed_update_all_backups
      File.exists?(VITEFAIT_FOLDERS[:backup]) || begin
        error "Le dossier des backups n'existe pas, je dois renoncer."
        return
      end
      Dir["#{VITEFAIT_FOLDERS[:backup]}/*"].each do |pth|
        tuto_name = File.basename(pth)
        tuto = new(tuto_name)
        if tuto.exists?
          # On teste la "vraie" date de modification du dossier,
          # c'est-à-dire la date de dernière modification d'un de ses
          # fichiers ou dossier.
          if Folder.new(tuto.current_folder).mtime > Folder.new(pth).mtime
            tuto.proceed_backup
          end
        end
      end #/fin de boucle sur tous les backup
    end

  end #/<< self
end #/ViteFait
