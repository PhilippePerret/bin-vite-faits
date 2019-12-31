# encoding: UTF-8
=begin
  Module pour l'upload du fichier final
=end
class ViteFait
  def exec_upload
    unless final_tutoriel_exists?
      yesNo("La vidéo du tutoriel final n'existe pas. Veux-tu vraiment ouvrir l'upload ?…") || return
    end
    clear
    notice <<-EOT
=== UPLOAD de la vidéo “#{titre}” (#{name}) ===

Je vais ouvrir :
  + le dossier contenant la vidéo finale,
  + Safari sur la page d'upload de la chaine Scrivener.

Pour s'identifier, utiliser le compte Yahoo normal
avec le mot de passe normal.

Rappels :

TITRE
#{titre}

DESCRIPTION
Dans la série des “vite faits”, #{description}

    EOT

    # Vérifier que ce projet contient bien la vidéo finale
    sleep 5

    `open -a Safari "https://studio.youtube.com/channel/UCWuW11zTGdNfoChranzBMxQ/videos/upload?d=ud&filter=%5B%5D&sort=%7B%22columnType%22%3A%22date%22%2C%22sortOrder%22%3A%22DESCENDING%22%7D"`

    if File.exists?(exports_folder)
      `open -a Finder "#{exports_folder}"`
    else
      error <<-EOE

Impossible de trouver le dossier des exports (*), je
ne peux pas vous présenter la vidéo à uploader…
(* )#{exports_folder}"
      EOE
    end

    if final_tutoriel_exists?
      yesNo("Après l'upload et le traitement YouTube (et seulement après), clique sur 'y' pour enregistrer l'ID YouTube du tutoriel.") || return
      require_module('youtube')
      set_youtube_id
    end
  end #/exec_upload
end #/ViteFait
