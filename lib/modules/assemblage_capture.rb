# encoding: UTF-8
class ViteFait

  def exec_assemble_capture(nomessage = false)
    puts "🔧  Vérification de la validité des fichiers capture…"

    # S'assurer que le fichier de capture existe
    src_path || return

    # S'assurer que le fichier voix existe
    voice_capture_exists?(true) || return

    # Produire le fichier aac si nécessaire
    unless File.exists?(voice_aac)
      cmd = "ffmpeg -i \"#{vocal_capture_path}\" \"#{voice_aac}\""
      COMMAND.options[:verbose] || cmd << " 2> /dev/null"
      res = `#{cmd}`
      if File.exists?(voice_aac)
        notice "--> Fichier voix AAC produit avec succès 👍"
      else
        return error "Impossible de produire le fichier voix AAC. Je dois renoncer."
      end
    end

    # Produire le fichier mp4 si nécessaire
    unless mp4_capture_exists?
      capture_to_mp4
      if mp4_capture_exists?
        notice "---> Fichier capture MP4 produit avec succès 👍"
      else
        return error "Impossible de produire le fichier capture MP4… Je dois renoncer."
      end
    end

    # On produit une copie sans son, qui servira de base
    mp4_copy_path = pathof("#{name}-copie.mp4")
    File.unlink(mp4_copy_path) if File.exists?(mp4_copy_path)
    res = `ffmpeg -i "#{mp4_path}" -c copy -an "#{mp4_copy_path}" 2> /dev/null`
    # ATTENTION : ici, pas question de supprimer le 2> /dev/null,
    # mêmem si la verbosité a été demandée, car cela empêcherait
    # l'assemblage.
    if File.exists?(mp4_copy_path)
      notice "---> Production de la copie de travail 👍"
    else
      return error "La copie de travail n'a pas pu être produite. Je dois renoncer."
    end

    # On doit détruire le mp4
    File.unlink(mp4_path)

    # Commande finale pour assembler l'image et le son
    notice "📦  Assemblage en cours, merci de patienter…"
    # version avec la copie sans le son :
    cmd = "ffmpeg -i \"#{mp4_copy_path}\" -i \"#{vocal_capture_path}\" -codec copy -shortest \"#{mp4_path}\" 2> /dev/null"
    res = `#{cmd}`
    if File.exists?(mp4_path)
      notice "---> Assemblage de la capture MP4 exécutée avec succès 📦 👍"
    else
      error "Une erreur est survenue, je n'ai pas pu produire le fichier…"
      FileUtils.copy(mp4_copy_path, mp4_path)
    end

    # On peut détruire la copie
    File.unlink(mp4_copy_path)

  end #/exec_assemblage_capture

end #/ViteFait
