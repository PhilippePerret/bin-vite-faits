# encoding: UTF-8
class ViteFait

  def exec_capture_to_mp4
    # On doit trouver la vidéo
    unlink_if_exist([mp4_path,ts_path])
    if !File.exists?(src_path)
      error "Le fichier '#{src_path}' est introuvable…"
      error "🖐  Impossible de procéder au traitement."
    else
      cmd = "ffmpeg -i \"#{src_path}\""

      # On doit la raccourcir
      unless COMMAND.options[:no_crop]
        # Pour raccourcir la vidéo (ne pas voir l'arrêt)
        duree_raccourcie = (Video.dureeOf(src_path) - 2).to_i.as_horloge
        cmd << " -ss 00:00:00 -t #{duree_raccourcie}"
      end

      COMMAND.params[:speed] && begin
        coef = {'2' => '0.5', '1.5' => '0.75'}[COMMAND.params[:speed]]
        coef ||= COMMAND.params[:speed]
        cmd << " -vf \"setpts=#{coef}*PTS\""
      end
      cmd << " \"#{mp4_path}\""
      COMMAND.options[:verbose] || cmd << " 2> /dev/null"
      notice "\n* Fabrication du fichier ./Operations/capture.mp4. Merci de patienter…"
      res = `#{cmd}`
      if File.exists?(mp4_path)
        notice "= 👍  Fichier mp4 fabriqué avec succès."
        notice "= Vous pouvez procéder à l'assemblage dans le fichier '#{name}.screenflow' ou à l'assemblage automatique."
      else
        error "= Le fichier '#{mp4_path}' n'a pas pu être fabriqué…"
      end
    end
  end

end  #/ViteFait
