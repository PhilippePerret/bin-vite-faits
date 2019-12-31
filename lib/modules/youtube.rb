# encoding: UTF-8
class ViteFait
  def set_youtube_id
    clear
    notice <<-EOT
=== Définition de l'ID YouTube de “#{name}” ===

La vidéo finale doit avoir été uploadée sur YouTube
et traitée.

    EOT
    begin
      yid = prompt("ID youtube")
      if yid.nil?
        yesOrStop("Il faut entrer l'ID de la vidéo. Dois-je poursuivre ?")
      end
    end while yid.nil?
    informations.set(youtube_id: yid)
  end
end #/ViteFait
