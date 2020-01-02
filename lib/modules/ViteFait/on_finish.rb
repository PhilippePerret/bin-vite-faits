# encoding: UTF-8
=begin
  Procédure appelée à la fin de la commande, pour vérification
=end
class ViteFait
class << self

  def check_finish
    check_manuels
    check_trash
    check_backups
  end


  # On vide de la corbeille les éléments très vieux
  def check_trash
    limite = Time.now.to_i - 7 * 24 * 3600
    Dir["#{trash_folder}/**/*.*"].each do |pth|
      name = File.basename(pth)
      time = name.split('-').first.to_i
      if time < limite
        # <= L'élément est vieux de plus d'une semaine
        # => On peut le détruire
        FileUtils.remove(pth)
      end
    end
  end

  def check_manuels
    # Les deux manuels PDF
    # --------------------
    # On vérifie que le manuel sur le disque et sur l'ordinateur soient
    # synchronisés, en sachant qu'on peut actualiser soit l'un soit l'autre
    plaptop = VITEFAIT_PDF_MANUAL_PATH_ON_LAPTOP
    pdisque = VITEFAIT_PDF_MANUAL_PATH
    checksum_laptop = Digest::SHA2.file(plaptop).hexdigest
    checksum_disque = Digest::SHA2.file(pdisque).hexdigest
    if checksum_laptop != checksum_disque
      # Il faut dupliquer l'un des fichiers, qui n'est pas
      # à jour.
      mtime_laptop = File.stat(plaptop).mtime
      mtime_disque = File.stat(pdisque).mtime
      srcdst = [plaptop,pdisque]
      srcdst.reverse! if mtime_disque > mtime_laptop
      src, dst = srcdst
      IO.copy_with_care(src,dst,'manuel PDF',true)
    end
  end


  def check_backups
    # Vérification des backups
    if File.exists?(VITEFAIT_FOLDERS[:backup])
      all_backup_uptodate = true
      Dir["#{VITEFAIT_FOLDERS[:backup]}/*"].each do |pth|
        tuto_name = File.basename(pth)
        tuto = new(tuto_name)
        if tuto.exists?
          # On teste la "vraie" date de modification du dossier,
          # c'est-à-dire la date de dernière modification d'un de ses
          # fichiers ou dossier.
          if Folder.new(tuto.current_folder).mtime > Folder.new(pth).mtime
            error "Le backup du tutoriel “#{tuto.titre||tuto.name}” n'est pas à jour."
            all_backup_uptodate = false
          end
        end
      end #/fin de boucle sur tous les backup
      unless all_backup_uptodate
        warn "Pour actualiser tous les backups des tutoriels, jouer la commande :\nvitefait backup all"
      end
    end
  end
end #/<< self
end #/ ViteFait
