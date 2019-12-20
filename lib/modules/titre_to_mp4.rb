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

    cmd = "ffmpeg -i \"#{titre_mov}\" -i "

    # On doit la raccourcir
    unless COMMAND.options[:no_crop]
      # Pour raccourcir la vidéo (ne pas voir l'arrêt)
      duree_raccourcie = (Video.dureeOf(src_path) - 1).to_i.as_horloge
      cmd << " -ss 00:00:00 -t #{duree_raccourcie}"
    end

    cmd << "\"#{self.class.machine_a_ecrire_path}\" -codec copy -shortest \"#{titre_mp4}\""
    # Pas d'option verbose, ici, il faut obligatoirement envoyer à /dev/null
    # lorsqu'on assemble du son
    cmd << " 2> /dev/null"

    if COMMAND.options[:verbose]
      puts "\n\n---- Commande jouée : #{cmd}"
    end

    # Jouer la commande
    res = `#{cmd}`
    
    if File.exists?(titre_mp4)
      notice "= 👍  Fichier titre mp4 fabriqué avec succès."
    else
      error "Le fichier titre mp4 n'a pas pu être fabriqué…"
    end
  end
end #/ ViteFait
