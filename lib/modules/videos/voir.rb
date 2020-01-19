# encoding: UTF-8
=begin
  Module pour "voir" quelque chose, par exemple, voir la vidéo finale
  sur YouTube
=end
class ViteFait
  MSG({
    undefined_video: "🚫  La vidéo du tutoriel '%{name}' n'existe pas.",
    unknown_what: "🚫  Je ne sais pas comment montrer '%{what}'…"
    })
  def exec_voir what, options = {}
    what = SHORT_SUJET_TO_REAL_SUJET[what] || what
    method = "voir_#{what}".to_sym
    if self.respond_to?(method)
      send(method)
    else
      error( MSG(:unknown_what, {what: what}))
    end
  end #/exec_voir

  def voir_video
    youtube_id.nil? && begin
      return error(MSG(:undefined_video))
    end
    if COMMAND.options[:youtube] || COMMAND.options[:online]
      # Montrer la vidéo sur YouTube
      `open -a #{DEFAULT_BROWSER} "#{video_url}"`
    else
      # Montrer la vidéo sur le disque ou l'ordinateur
      `open -a 'QuickTime Player' "#{final_tutoriel_mp4}"`
      notice "Pour voir la vidéo sur Youtube, ajoute l'option --youtube :\n\tvitefait voir-video --youtube[ #{name}]"
    end
  end

  def voir_url_video
    youtube_id.nil? && begin
      return error(MSG(:undefined_video))
    end
    notice "Le lien vers la vidéo est : #{video_url}"
    notice "(mis dans le presse-papier)"
    Clipboard.copy(video_url)
  end
end #/ViteFait
