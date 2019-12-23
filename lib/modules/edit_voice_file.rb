# encoding: UTF-8
=begin

  Module pour éditer le fichier voix

=end
class ViteFait

  def edition_fichier_voix
    puts "Il faudra enregistrer le résultat au format AIFF (extension '.aiff')"
    sleep 4
    `open -a Audacity "#{vocal_capture_path}"`
    if yesNo("Dois-je convertir le fichier AIFF en fichier MP4 (normal) ?")
      File.exists?(vocal_capture_aiff_path) || raise(NotAnError.new("Impossible de trouver le fichier .aiff… Je ne peux pas prendre le nouveau fichier."))
      File.unlink(vocal_capture_path) if File.exists?(vocal_capture_path)
      cmd = "ffmpeg -i \"#{vocal_capture_aiff_path}\" \"#{vocal_capture_path}\""
      COMMAND.options[:verbose] || cmd << " 2> /dev/null"
      res = `#{cmd}`

      if File.exists?(vocal_capture_path)
        notice "👍  Fichier voice converti avec succès."
        File.unlink(vocal_capture_aiff_path) if File.exists?(vocal_capture_aiff_path)
      else
        raise NotAnError.new("Le fichier voix n'a pas été converti…\n(*) #{vocal_capture_path}")
      end
    end
  end

end #/ViteFait
