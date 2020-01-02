# encoding: UTF-8
class ViteFait

  def exec_assemble_titre
    unless File.exists?(titre_mov)
      raise "🖐  Le fichier `Titre.mov` est introuvable. Il faut capturer le titre en se servant du fichier Titre.scriv"
    end
    unless File.exists?(self.class.machine_a_ecrire_aac)
      if File.exists?(self.class.machine_a_ecrire_aiff)
        cmd = "ffmpeg -i \"#{self.class.machine_a_ecrire_aiff}\" \"#{self.class.machine_a_ecrire_aac}\""
        COMMAND.options[:verbose] || cmd << " 2> /dev/null"
        res = `#{cmd}`
        IO.check_existence(self.class.machine_a_ecrire_aac, {interactive:true})
      end
      unless File.exists?(self.class.machine_a_ecrire_aac)
        raise "🖐  Impossible de trouver le son de machine à écrire (#{self.class.machine_a_ecrire_aac}). Or j'en ai besoin pour créer le titre."
      end
    end

    unlink_if_exist([record_titre_mp4, titre_prov_mp4, record_titre_ts])

    # On enregistre le titre avec 1 secondes en moins
    # Et en l'inversant
    #
    # Noter que l'inversion se fait avant le raccourcissement, ce qui
    # explique que maintenant, pour définir la longueur, on rabote le
    # début et non plus la fin de la vidéo.
    #
    notice "📦  Fabrication du fichier de titre assemblé. Merci de patienter…"
    cmd = "ffmpeg -i \"#{titre_mov}\""
    # On doit la raccourcir
    if COMMAND.options[:no_crop]
      # On n'ajoute pas de modification de durée
    elsif COMMAND.params[:crop]
      # Pour raccourcir la vidéo (ne pas voir l'arrêt)
      #  crop=0.6 =>
      secs, frms = COMMAND.params[:crop].split('.')
      frms = frms.to_i
      secs = secs.to_i
      # if frms > 0
      #   secs = secs + 1
      #   frms = 24 - frms
      # end
      # duree_raccourcie = (Video.dureeOf(titre_mov) - secs).to_i.as_horloge
      # duree_raccourcie += ".#{frms}" unless frms == 0
      # cmd << " -ss 00:00:00 -t #{duree_raccourcie}"
      # Maintenant que c'est inversé
      cmd << " -ss 00:00:#{secs.to_s.rjust(2,'0')}.#{frms}"
    else
      # Pour raccourcir la vidéo (ne pas voir l'arrêt)
      duree_raccourcie = (Video.dureeOf(titre_mov) - 1).to_i.as_horloge
      # cmd << " -ss 00:00:00 -t #{duree_raccourcie}"
      cmd << " -ss 00:00:01"
    end

    # Pour l'inversion
    cmd << " -vf reverse"

    cmd << " #{titre_prov_mp4}"
    COMMAND.options[:verbose] || cmd << " 2> /dev/null"

    # puts "---- cmd = #{cmd}"
    res = `#{cmd}`

    cmd = "ffmpeg -i \"#{titre_prov_mp4}\""
    cmd << " -i \"#{self.class.machine_a_ecrire_aac}\" -codec copy -shortest \"#{record_titre_mp4}\""
    # Pas d'option verbose, ici, il faut obligatoirement envoyer à /dev/null
    # lorsqu'on assemble du son
    cmd << " 2> /dev/null"

    if COMMAND.options[:verbose]
      puts "\n\n---- Commande jouée : #{cmd}"
    end

    # Jouer la commande
    res = `#{cmd}`

    IO.remove_with_care(titre_prov_mp4,'fichier titre provisoire',false)

    if File.exists?(record_titre_mp4)
      notice "--> 👍  Fichier titre mp4 fabriqué avec succès."
      save_last_logic_step
    else
      error "Le fichier titre mp4 n'a pas pu être fabriqué…"
    end
  end
end #/ ViteFait
