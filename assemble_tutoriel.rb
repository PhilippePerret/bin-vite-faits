# #!/usr/bin/env ruby
# # encoding: UTF-8
#
# SPEED_TO_COEF = {
#   "2"   =>  "0.5",
#   "1.5" =>  "0.75",
#   "1,5" =>  "0.75"
# }
# tutoFolder = nil
# CONCAT_DATA = {
#   extension: "mov"
# }
#
# ARGV.each do |arg|
#   puts "arg = '#{arg}'"
#   if tutoFolder.nil?
#     tutoFolder = arg
#   else
#     key, value = arg.split('=')
#     CONCAT_DATA.merge!(key.to_sym => value)
#   end
# end
#
# # LES NOMS ET PATHS DES FICHIERS UTILES
# PREF_CAPTURE = "2_En_chantier/#{tutoFolder}/#{tutoFolder}"
# FILES = {
#   capture:{
#     pref:PREF_CAPTURE,
#     src:"#{PREF_CAPTURE}.#{CONCAT_DATA[:extension]}",
#     dst:"#{PREF_CAPTURE}_complete.mp4"
#   },
#   intro:{
#     pref:"Materiel/INTRO-vite-faits-sonore"
#   },
#   final:{
#     pref:"Materiel/FINAL-vite-faits-sonore"
#   }
# }
# ['mp4','ts'].each do |suf|
#   FILES.each do |kfile, dfile|
#     dfile.merge!(suf.to_sym => "#{dfile[:pref]}.#{suf}")
#   end
# end
#
# # Le fichier capture mp4 doit être fabriqué, sauf si le fichier source n'existe
# # plus, ce qui signifie qu'il a été supprimé
# if File.exists?(FILES[:capture][:src])
#   File.unlink(FILES[:capture][:mp4]) if File.exists?(FILES[:capture][:mp4])
#   speed_change = if CONCAT_DATA[:speed]
#     coef = SPEED_TO_COEF[CONCAT_DATA[:speed]] || CONCAT_DATA[:speed]
#     " -vf \"setpts=#{coef}*PTS\""
#   else '' end
#   cmd = "ffmpeg -i \"#{FILES[:capture][:src]}\"#{speed_change} \"#{FILES[:capture][:mp4]}\""
#   puts "\n--- Commande de fabrication de la capture : #{cmd}"
#   res = `#{cmd} 2> /dev/null`
# elsif !File.exists?(FILES[:capture][:mp4])
#   puts "ERREUR : Aucun fichier source et aucun fichier .mp4, je ne peux rien faire."
#   exit(1)
# end
#
# # Fabriquer tous les fichier .ts (ça vaut pour l'intro, pour la capture et
# # pour le final)
# FILES.each do |kfile, dfile|
#   next if File.exists?(dfile[:ts])
#   cmd = "ffmpeg -i \"#{dfile[:mp4]}\" -c copy -bsf:v h264_mp4toannexb -f mpegts \"#{dfile[:ts]}\" 2> /dev/null"
#   res = `#{cmd}`
# end
#
# # Le fichier final doit être détruit s'il existe
# File.unlink(FILES[:capture][:dst]) if File.exists?(FILES[:capture][:dst])
# cmd = "ffmpeg -i \"concat:#{FILES[:intro][:ts]}|#{FILES[:capture][:ts]}|#{FILES[:final][:ts]}\" -c:a copy -bsf:a aac_adtstoasc \"#{FILES[:capture][:dst]}\""
# puts "\n---- Commande finale : '#{cmd}'"
# res = `#{cmd}`
