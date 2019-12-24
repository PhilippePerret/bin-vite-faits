# encoding: UTF-8
class ViteFait

  def exec_capture_to_mp4
    # On doit trouver la vidéo
    unlink_if_exist([mp4_path,mp4_cropped_path, ts_path])
    src_path(required=true) || return

    cmd = "ffmpeg -i \"#{src_path}\""

    # On doit la raccourcir
    # Note : fichier_ref sera le fichier à prendre pour produire
    # le mp4. Si on crop la fin, on prend le fichier mp4 produit
    fichier_ref =
      unless COMMAND.options[:no_crop]
        # Pour raccourcir la vidéo (ne pas voir l'arrêt)
        duree_initiale = Video.dureeOf(src_path)
        duree_raccourcie = (duree_initiale - 2).to_i.as_horloge
        puts "Raccourcissement de #{duree_initiale} à #{duree_raccourcie} "
        cmd << " -ss 00:00:00 -t #{duree_raccourcie} #{mp4_cropped_path}"
        COMMAND.options[:verbose] || cmd << " 2> /dev/null"
        `#{cmd}`
        mp4_cropped_path
      else
        src_path
      end

    cmd = "ffmpeg -i \"#{fichier_ref}\""

    COMMAND.params[:speed] && begin
      coefficiant = accelerator_for_speed(COMMAND.params[:speed])
      cmd << " -vf \"setpts=#{coefficiant}*PTS\""
      # puts "Accelerator : speed=#{COMMAND.params[:speed]} / coefficiant=#{coefficiant}"
    end
    cmd << " \"#{mp4_path}\""
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"
    notice "\n* Fabrication du fichier ./Operations/capture.mp4. Merci de patienter…"
    puts "Exécution en cours, merci de patienter…"
    res = `#{cmd}`
    if File.exists?(mp4_path)
      notice "= 👍  Fichier mp4 fabriqué avec succès."
    else
      NotAnError.new("🚫  Le fichier capture.mp4 (*) n'a pas pu être fabriqué…\(*) #{mp4_path}")
    end

    IO.remove_with_care(mp4_cropped_path,'fichier mp4 croppé',false)
  end

end  #/ViteFait
