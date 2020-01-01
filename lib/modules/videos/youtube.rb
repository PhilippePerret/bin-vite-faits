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

  # Méthode pour vérifier que la vidéo se trouve bien sur YouTube
  def is_video_on_youtube?
    url = "https://www.youtube.com/oembed?format=json&url=http://www.youtube.com/watch?v=#{youtube_id}"
    res = `cUrl "#{url}" 2> /dev/null`
    return res != 'Not Found'
  end


end #/ViteFait
