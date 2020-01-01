# encoding: UTF-8
=begin

  Module pour demander le nom du tutoriel

  Retourne le nom choisi, ou nil pour arrêter

=end

class ViteFait
class << self

  # Demande le nom du tutoriel
  # Note : ça n'est pas pour une création, le nom peut déjà
  # exister
  def ask_for_name(options = nil)
    tuto_name = nil
    begin
      tuto_name = prompt("Nom du tutoriel (minuscules et '-')")
      if tuto_name.nil?
        if yesNo('Voulez-vous vraiment arrêter ?')
          raise NotAnError.new(nil)
        end
      end
      if (tuto_name||'').gsub(/[a-z\-]/,'') != ''
        error "Un nom de tutoriel ne doit comporter que des lettres minuscules et le signe moins."
        tuto_name = nil
      end
    end while tuto_name.nil?

    return tuto_name
  end

  # Retourne true si le nom +name+ est valide pour un tutoriel,
  # s'il n'est pas déjà utilisé. Retourne false si le nom est invalide
  # ou que le tutoriel existe déjà.
  def is_valid_name?(name)

    # Le nom doit être valide dans sa forme
    name.nil? && not_an_error("Il faut définir le nom !")
    name.length > 4   || not_an_error("Il faut un nom d'au moins 4 lettres !")
    name.length < 33  || not_an_error("Le nom ne doit pas excéder les 32 signes (il en fait #{name.length}).")
    name.gsub(/[a-z\-]/,'') == '' || begin
      proposition = ''
      if name.gsub(/[a-z_]/,'') == ''
        good_name = name.gsub(/_/,'-')
        bad_folder = tutoriel_exists_with_name?(good_name)
        if bad_folder
          proposition = " Le nom '#{good_name}' serait valide, mais un\ntutoriel porte déjà ce nom."
        else
          proposition = " Tu pourrais par exemple utiliser le nom '#{good_name}'"
        end
      end
      not_an_error("Un nom de dossier de tutoriel ne doit contenir que des lettres minuscules et le trait d'union.#{proposition}".colonnize)
    end

    # On ne doit pas le trouver dans les dossiers
    # Noter que tous les dossiers, même le dossier backup, sont
    # checkés ci-dessous.
    # puts "VITEFAIT_FOLDERS = #{VITEFAIT_FOLDERS.inspect}"
    folder_ref = tutoriel_exists_with_name?(name)
    if folder_ref
      not_an_error("Ce nom est déjà utilisé pour un tutoriel dans le dossier #{folder_ref}.")
    end
    return true
  rescue NotAnError => e
    return error(e.message)
  end

  def tutoriel_exists_with_name?(name)
    VITEFAIT_FOLDERS.each do |klieu, pFolder|
      if File.exists?(File.join(pFolder, name))
        folder_ref = DATA_LIEUX[klieu] ? DATA_LIEUX[klieu][:hname] : 'dossier backup'
        return folder_ref
      end
    end
    return nil
  end

end #/ << self
end #/ViteFait
