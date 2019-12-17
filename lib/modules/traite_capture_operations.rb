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
      COMMAND.params[:speed] && begin
        coef = {'2' => '0.5', '1.5' => '0.75'}[COMMAND.params[:speed]]
        coef ||= COMMAND.params[:speed]
        cmd << "-vf \"setpts=#{coef}*PTS\""
      end
      cmd << " \"#{mp4_path}\""
      COMMAND.options[:verbose] && cmd << " 2> /dev/null"
      notice "\n* Fabrication du fichier .mp4. Merci de patienter…"
      res = `#{cmd}`
      if File.exists?(mp4_path)
        notice "= 👍  Fichier mp4 fabriqué avec succès."
        notice "= Vous pouvez procéder à l'assemblage dans le fichier '#{name}.screenflow'"
      else
        error "= Le fichier '#{mp4_path}' n'a pas pu être fabriquer…"
      end
    end
  end

end  #/ViteFait
