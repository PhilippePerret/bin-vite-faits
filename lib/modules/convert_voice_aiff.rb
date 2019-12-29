# encoding: UTF-8
class ViteFait

  def convert_voice_aiff_to_voice_mp4
    File.exists?(vocal_capture_aiff_path) || raise(NotAnError.new("Impossible de trouver le fichier .aiff… Je ne peux pas prendre le nouveau fichier."))
    IO.remove_with_care(vocal_capture_path,'fichier voix',false)
    cmd = "ffmpeg -i \"#{vocal_capture_aiff_path}\" \"#{vocal_capture_path}\""
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"
    puts "📦  Merci de patienter…"
    res = `#{cmd}`

    if File.exists?(vocal_capture_path)
      notice "👍  Fichier voice AIFF converti avec succès en MP4."
      IO.remove_with_care(vocal_capture_aiff_path,'fichier voix AIFF',false)
      save_last_logic_step
    else
      raise NotAnError.new("Le fichier voix n'a pas été converti…\n(*) #{vocal_capture_path}")
    end
  end
end #/ViteFait
