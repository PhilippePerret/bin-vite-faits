# encoding: UTF-8
=begin
  Module 'update', pour forcer l'actualisation
  à partir d'une certaine étape
=end
class ViteFait

  def update
    # L'étape à partir de laquelle il faudra opérer
    from_etape = COMMAND.params[:from] || COMMAND.params[:depuis]

    from_etape || begin
      return error "Il faut définir le paramètre :from ou :depuis"
    end

    # On cherche la clé fichier correspondant à l'étape
    # voulue
    from_index = nil
    DATA_KEYS_FILES_OPERATION.each_with_index do |kfile, index|
      kfile = kfile.to_sym
      if DATA_ALL_FILES[kfile][:from_update] == from_etape
        # On l'a trouvée
        from_index = index
        break
      end
    end

    from_index || begin
      error "L'étape #{from_etape} est inconnue. Les étapes possibles sont :"
      DATA_ALL_FILES.each do |kfile, dfile|
        dfile[:from_update] || next
        puts "\t#{dfile[:from_update]}: #{dfile[:hname]}"
      end
      puts "\n\n"
      return
    end

    # On fait la liste des fichiers à détruire
    removes =
      DATA_KEYS_FILES_OPERATION[from_index..-1].collect do |kfile|
        d = DATA_ALL_FILES[kfile.to_sym]
        path = File.join(current_folder, (d[:relpath] % {name: name}))
        File.exists?(path) || next
        d.merge(path: path)
      end.compact

    # Confirmation
    from_etape_data = DATA_ALL_FILES[DATA_KEYS_FILES_OPERATION[from_index].to_sym]

    clear
    notice "= Update From ="
    puts <<-EOT

Confirmes-tu l'update depuis l'étape (comprise) :

\t“#{from_etape_data[:hname]}”

Tous les fichiers qui peuvent exister, à partir de cette étape,
seront supprimés. Il s'agit de :

    EOT
    removes.each do |remove|
      puts "\t- #{remove[:relpath] % {name:name}} : #{remove[:hname]}"
    end

    yesNo("Tu confirmes bien ?") || return

    # On peut procéder à la destruction
    all_removed = true
    removes.each do |remove|
      File.exists?(remove[:path]) || next
      `rm "#{remove[:path]}"`
      File.exists?(remove[:path]) && begin
        error "Bizarrement, le fichier #{remove[:relpath]} n'a pas pu être détruit…"
        all_removed = false
      end
    end

    if all_removed
      notice "Tous les fichiers ont été supprimés avec succès. 👍"
    end

  end #/update


end #/ViteFait
