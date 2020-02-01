# encoding: UTF-8
=begin
  Définition des valeurs de configuration

  Pour récupérer une valeur, utiliser :

      Configuration.<nom/clé de la configuration>
      CONFIG[:<nom/clé de la configuration>]

=end
CONFIG = {}
class Configuration
  def self.define
    yield Configuration.new()
  end
  def method_missing method, *args, &block
    method = method.to_s
    if method.end_with?('=')
      CONFIG.merge!( method[0...-1].to_sym => args.first)
    else
      raise e
    end
  end
end

Configuration.define do |config|

config.default_browser = 'Firefox'

# Fréquence de publication
# ------------------------
# Cette valeur définit la fréquence de publication des tutoriels, elle
# servira à déplacer les dates lors d'insertion (une nouvelle date en remplaçant
# une déja définie)
config.frequence_publication = 7

# Dossier de captures
# -------------------
# C'est le dossier où le mac enregistre les captures d'écran,
# lorsque l'on enregistre avec Cmd,Maj,5.
config.captures_folder = File.join('/Volumes','MacOSCatalina','Captures')

# Dossier Vite-Fait sur l'ordinateur
# ----------------------------------
# Son chemin d'accès
config.laptop_folder = File.join(Dir.home,'Movies','Tutoriels','SCRIVENER','LES_VITE_FAITS')

# Dossier Vite-Fait sur le disque principal
# -----------------------------------------
# C'est son chemin d'accès qui doit être défini ici
config.disk_folder = File.join('/Volumes','MacOSCatalina','Screencasts','SCRIVENER','LES_VITE_FAITS')

# Dossier pour faire des backups sur l'autre disque
# -------------------------------------------------
# C'est son chemin d'accès qui doit être défini ici
config.backup_folder = File.join('/Volumes','BackupPlusDrive','Miroir-MacOSCatalina','Screencasts','SCRIVENER','LES_VITE_FAITS','Backups_ViteFaits')

end

# puts "CONFIG = #{CONFIG.inspect}"
