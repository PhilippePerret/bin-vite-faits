# encoding: UTF-8
class ViteFait

  # Enregistre l'identifiant de la vidéo sur YouTube, en vérifiant
  # sa présence, sauf si +checkit+ est false (quand on enregistre l'ID
  # après avec uploadé la vidéo et la programmer pour plus tard)
  #
  # +return+ Retour true si la vidéo a été trouvée
  def set_youtube_id(checkit = true)
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

    # Pour s'assurer que l'upload a bien eu lieu, on essaie
    # d'atteindre la vidéo
    if checkit
      if is_video_on_youtube?
        notice "J'ai trouvé la vidéo sur YouTube 👍"
        informations.set(uploaded: true)
        return true
      else
        informations.set(uploaded: false)
        informations.set(youtube_id: nil)
        raise(NotAnError.new("🚫  Je n'ai pas pu trouver la vidéo sur YouTube, malheureusement…"))
      end
    end
  end

  # Méthode pour vérifier que la vidéo se trouve bien sur YouTube
  def is_video_on_youtube?
    url = "https://www.youtube.com/oembed?format=json&url=http://www.youtube.com/watch?v=#{youtube_id}"
    res = `cUrl "#{url}" 2> /dev/null`
    return res != 'Not Found'
  end


end #/ViteFait
