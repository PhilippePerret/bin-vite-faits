# encoding: UTF-8
=begin

  Module pour éditer le fichier voix

=end
class ViteFait

  def edition_fichier_voix
    puts <<-EOT
Il faudra enregistrer le résultat au format AIFF en utilisant
le menu "Fichier > Exporter > Exporter l'audio…" ou le raccour-
ci CMD+MAJ+E. L'extension devra être “.aiff”.

\033[1;31mATTENTION : quand on exporte depuis Audacity, on ne se retrouve
pas dans le bon dossier.\033[0m

Raccourcis pratiques à avoir en tête :

---------------------------------------------------------------------
|  ⌘L         | Pour rendre silencieuse la portion sélectionnée.    |
---------------------------------------------------------------------
|  ⌘⇧E        | Exporter le fichier son                             |
---------------------------------------------------------------------


    EOT
    sleep 4
    `open -a Audacity "#{vocal_capture_path}"`
    sleep 15
    if yesNo("Dois-je convertir le fichier AIFF en fichier MP4 (normal) ?")
      require_module('convert_voice_aiff')
      convert_voice_aiff_to_voice_mp4
    end
  end

end #/ViteFait
