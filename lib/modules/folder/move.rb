# encoding: UTF-8
class ViteFait

  ERRORS_MOVE = {
    no_from_lieu: "Soit le tutoriel n'existe pas dans le lieu spécifié, soit il n'existe pas.",
    no_destination: "Il faut définir le lieu de destination.",
    unknown_lieu_to: "Le lieu de destination est inconnu.",
    unknown_lieu_from: "Le lieu source est inconnu…",
    same_lieux: "Le lieu source est le même que le lieu de destination… C'est absurde.",
    no_source: "Le dossier source est introuvable…"
  }
  # Procède au déplacement du dossier du tutoriel
  def exec_move
    from_lieu = COMMAND.params[:from] || COMMAND.params[:de] || lieu
    new_lieu  = COMMAND.params[:vers] || COMMAND.params[:to]

    from_lieu || raise(ERRORS_MOVE[:no_from_lieu])
    new_lieu  || raise(ERRORS_MOVE[:no_destination])
    from_lieu = from_lieu.to_sym
    new_lieu  = new_lieu.to_sym
    DATA_LIEUX.key?(from_lieu)  || raise(ERRORS_MOVE[:unknown_lieu_from])
    DATA_LIEUX.key?(new_lieu)   || raise(ERRORS_MOVE[:unknown_lieu_to])
    from_lieu != new_lieu || raise(ERRORS_MOVE[:same_lieux])

    from_lieu_path  = send("#{from_lieu}_folder_path")
    new_lieu_path   = send("#{new_lieu}_folder_path")

    File.exists?(from_lieu_path) || raise(ERRORS_MOVE[:no_source])

    # OK, on peut procéder à l'opération
    notice <<-EOT
Déplacement :
<- #{from_lieu_path}
-> #{new_lieu_path}
    EOT
    notice_prov("Merci de patienter…")
    FileUtils.move(from_lieu_path, new_lieu_path)
    if File.exists?(new_lieu_path)
       notice "---> Déplacement effectué avec succès 👍"
       reset
       if new_lieu == :published
         # <= Déplacement vers le dossier publié
         # => On fait un backup automatique
         if File.exists?(VITEFAIT_FOLDERS[:backup])
           COMMAND.options[:backup] ||= yesNo("Dois-je faire un backup de sécurité du tutoriel ?")
           if COMMAND.options[:backup]
             require_module('folder/backup')
             proceed_backup
           end
         else
           warn("Si un dossier backup était défini (dans config.rb), je pourrais faire un backup de sécurité.".colonnize)
         end
       end
     else
       error "\n🚫  Le dossier de destination n'a pas pu être créé…"
     end

     if File.exists?(from_lieu_path)
       puts "Le lieu source existe toujours"
     end

  rescue Exception => e
    error e.message
    error "Je ne peux pas procéder au déplacement."
  end #/exec_move


end #/ViteFait
