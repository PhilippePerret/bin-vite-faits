# encoding: UTF-8
class ViteFait
  def exec_keep_only_folder
    lelieu = COMMAND.params[:lieu]
    lelieu || raise("Il faut indiquer le lieu du dossier à conserver (avec le paramètre 'lieu=...')")
    path = send("#{lelieu}_folder_path")
    path || raise("Le lieu '#{lelieu}' est inconnu. Désolé (utiliser 'attente','chantier','chantierd', 'completed' ou 'published').")
    File.exists?(path) || raise("Le dossier '#{lelieu}' n'existe pas, je ne peux pas garder celui-là.")

    # C'est OK, on détruit les dossiers autre part
    lelieu = lelieu.to_sym
    bad_lieux = []
    DATA_LIEUX.each do |klieu, dlieu|
      next if klieu == lelieu
      path = send("#{klieu}_folder_path")
      if File.exists?(path)
        bad_lieux << "\t:#{klieu} (#{dlieu[:hname]})"
        dlieu[:path] = path
      end
    end

    if bad_lieux.count > 0
      puts "\nJe dois détruire le ou les dossiers :\n\n"
      bad_lieux.each { |lelieu| puts lelieu }
      if yesNo("\nConfirmez-vous l'opération ?")
        notice "Je procède à la destruction"
        DATA_LIEUX.each do |klieu, dlieu|
          next if klieu == lelieu
          if dlieu[:path]
            path = dlieu[:path]
            FileUtils.rm_rf(path)
            if File.exists?(path)
              error "🚫  Le dossier '#{path}' n'a pas pu être détruit."
            else
              notice "---> Destruction de #{klieu.inspect} 👍"
            end
          end
        end
        if valid?
          notice "\nLe tutoriel est maintenant valide 👍"
        end
      end # s'il y a des lieux à supprimer
    else
      notice "Le tutoriel ne se trouve que dans le lieu #{lelieu.inspect}."
    end
  rescue Exception => e
    return error e.message
  end #/exec_keep_only_folder
end #/ViteFait
