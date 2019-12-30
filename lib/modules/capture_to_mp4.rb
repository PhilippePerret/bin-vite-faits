# encoding: UTF-8
class ViteFait

  def exec_capture_to_mp4
    # On doit trouver la vidéo
    unlink_if_exist([record_operations_mp4,record_operations_cropped_mp4, record_operations_ts])
    record_operations_path(required=true) || return

    cmd = "ffmpeg -i \"#{record_operations_path}\""

    # On doit la raccourcir
    # Note : fichier_ref sera le fichier à prendre pour produire
    # le mp4. Si on crop la fin, on prend le fichier mp4 produit
    fichier_ref =
      unless COMMAND.options[:no_crop]
        # Pour raccourcir la vidéo (ne pas voir l'arrêt)
        duree_initiale = Video.dureeOf(record_operations_path)
        duree_initiale_f = duree_initiale.to_i.as_horloge
        duree_raccourcie = (duree_initiale - 2).to_i.as_horloge
        puts "Raccourcissement de #{duree_initiale_f} à #{duree_raccourcie} "
        cmd << " -ss 00:00:00 -t #{duree_raccourcie} #{record_operations_cropped_mp4}"
        COMMAND.options[:verbose] || cmd << " 2> /dev/null"
        `#{cmd}`
        record_operations_cropped_mp4
      else
        record_operations_path
      end


    cmd = "ffmpeg -i \"#{fichier_ref}\""

    if operations[:accelerator] || COMMAND.params[:speed]
      accel = COMMAND.params[:speed] || operations[:accelerator]
      coefficiant = accelerator_for_speed(accel)
      cmd << " -vf \"setpts=#{coefficiant}*PTS\" -an"
      if COMMAND.params[:speed]
        # Il faut l'enregistrer dans les informations
        informations.set(accelerator: COMMAND.params[:speed].to_f)
      end
      # puts "Accelerator : speed=#{COMMAND.params[:speed]} / coefficiant=#{coefficiant}"
    end
    cmd << " \"#{record_operations_mp4}\""
    # puts "Command = #{cmd}"
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"
    notice "\n* Fabrication du fichier ./Operations/capture.mp4. Merci de patienter…"
    puts "Exécution en cours, merci de patienter…"
    res = `#{cmd}`
    if File.exists?(record_operations_mp4)
      notice "= 👍  Fichier mp4 fabriqué avec succès."
    else
      NotAnError.new("🚫  Le fichier capture.mp4 (*) n'a pas pu être fabriqué…\(*) #{record_operations_mp4}")
    end

    IO.remove_with_care(record_operations_cropped_mp4,'fichier mp4 croppé',false)
  end

end  #/ViteFait
