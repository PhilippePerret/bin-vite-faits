# encoding: UTF-8
class ViteFait

  def exec_titre_to_mp4
    unless File.exists?(titre_mov)
      raise "🖐  Le fichier `Titre.mov` est introuvable. Il faut capturer le titre en se servant du fichier Titre.scriv"
    end
    unless File.exists?(self.class.machine_a_ecrire_path)
      raise "🖐  Impossible de trouver le son de machine à écrire (#{self.class.machine_a_ecrire_path}). Or j'en ai besoin pour créer le titre."
    end

    unlink_if_exist([titre_mp4, titre_ts])

    cmd = "ffmpeg -i \"#{titre_mov}\" -i \"#{self.class.machine_a_ecrire_path}\" -codec copy -shortest \"#{titre_mp4}\""
    COMMAND.options[:verbose] && cmd << ' 2> /dev/null'
    # puts "\n\n---- Commande jouée : #{cmd}"
    res = `#{cmd}`
    if File.exists?(titre_mp4)
      notice "= 👍  Fichier titre mp4 fabriqué avec succès."
    else
      error "Le fichier titre mp4 n'a pas pu être fabriqué…"
    end
  end
end #/ ViteFait
