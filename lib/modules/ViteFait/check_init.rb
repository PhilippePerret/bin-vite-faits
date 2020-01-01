# encoding: UTF-8
=begin
  Module qui, à l'initialisation, vérifie l'intégrité de
  l'application.
=end
class ViteFait
class << self
  def check_init
    MSG({
      folder_chantier_unfound: "
ERROR : le dossier des tutoriels en chantier (*) est introuvable…
(*) #{VITEFAIT_CHANTIER_FOLDER}
      ",
      folder_laptop_unfound: "
ERROR : Le dossier vite-faits sur le disque (*) est introuvable…
(*) #{VITEFAIT_FOLDER_ON_LAPTOP}
      ",
      folder_disque_unfound:"
ERROR : Le dossier Vite-faits sur le disque (*) est introuvable…
(*) #{VITEFAIT_FOLDER_ON_DISK}
      ",
      manuel_html_unfound: "
ATTENTION : le fichier HTML du manuel (permettant de ce rendre
à une page précise) est introuvable. Il faut exporter le fichier
Markdown en HTML dans :
#{VITEFAIT_HTML_MANUAL_PATH}
      ",
      manuel_html_outofdata: <<-EOT
Le fichier HTML du manuel (*) n'est pas à jour. Il faut l'actualiser
en exportant le manuel markdown en HTML à l'adresse :
(*) #{VITEFAIT_HTML_MANUAL_PATH}
      EOT
      })
    # Le dossier sur l'ordinateur
    if File.exists?(VITEFAIT_FOLDER_ON_LAPTOP)
      unless File.exists?(VITEFAIT_CHANTIER_FOLDER)
        raise FatalError.new(MSG(:folder_chantier_unfound))
      end
    else
      raise FatalError.new(MSG(:folder_laptop_unfound))
    end

    unless File.exists?(VITEFAIT_FOLDER_ON_DISK)
      raise NonFatalError.new(MSG(:folder_disque_unfound))
    end

    if File.exists?(VITEFAIT_HTML_MANUAL_PATH)
      if File.stat(VITEFAIT_HTML_MANUAL_PATH).mtime < File.stat(VITEFAIT_MARKDOWN_MANUAL_PATH).mtime
        warn(MSG(:manuel_html_outofdata))
      end
    else
      raise FatalError.new(MSG(:manuel_html_unfound))
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
    exit
  end #/check_init

  # On met ici les vérifications qu'on peut faire à la fin
  # Appelée par ViteFait.finish
  def check_before_finish
    require_module('ViteFait/on_finish')
    check_finish
  end
end #/<< self
end #/ViteFait
