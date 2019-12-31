# encoding: UTF-8
class ViteFait

  def convert_voice_aiff_to_voice_mp4
    File.exists?(record_voice_aiff) || raise(NotAnError.new("Impossible de trouver le fichier .aiff… Je ne peux pas prendre le nouveau fichier."))
    IO.remove_with_care(record_voice_path,'fichier voix',false)
    cmd = "ffmpeg -i \"#{record_voice_aiff}\" \"#{record_voice_path}\""
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"
    puts "📦  Merci de patienter…"
    res = `#{cmd}`

    if File.exists?(record_voice_path)
      notice "👍  Fichier voice AIFF converti avec succès en MP4."
      IO.remove_with_care(record_voice_aiff,'fichier voix AIFF',false)
      save_last_logic_step
    else
      raise NotAnError.new("Le fichier voix n'a pas été converti…\n(*) #{record_voice_path}")
    end
  end
end #/ViteFait
