# encoding: UTF-8
=begin
  Module qui, à l'initialisation, vérifie l'intégrité de
  l'application.
=end
class ViteFait
class << self
  def check_init

    # Le dossier sur l'ordinateur
    if File.exists?(VITEFAIT_FOLDER_ON_LAPTOP)
      unless File.exists?(VITEFAIT_CHANTIER_FOLDER)
        raise FatalError.new("ERROR : Le dossier '#{VITEFAIT_CHANTIER_FOLDER}' est introuvable…")
      end
    else
      raise FatalError.new("ERROR : Le dossier '#{VITEFAIT_FOLDER_ON_LAPTOP}' est introuvable…")
    end

    unless File.exists?(VITEFAIT_FOLDER_ON_DISK)
      raise NonFatalError.new("ERROR : Le dossier '#{VITEFAIT_FOLDER_ON_DISK}' est introuvable…")
    end

  rescue NonFatalError => e
    error e.message
    error <<-EOE
  Cette erreur n'est pas fatale mais peut entraver certaines
  opérations demandées.
    EOE
  rescue FatalError => e
    error e.message
    error "Je ne vais pas pouvoir procéder à l'opération."
    raise e
  end #/check_init

  # On met ici les vérifications qu'on peut faire à la fin
  # Appelée par ViteFait.finish
  def check_before_finish

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
end #/<< self
end #/ViteFait
