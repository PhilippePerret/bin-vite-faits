# encoding: UTF-8
class ViteFait
# ---------------------------------------------------------------------
#   INSTANCE
# ---------------------------------------------------------------------
def exec_open what, edition = nil

  if edition === nil
    edition = !!COMMAND.options[:edit]
  end

  COMMAND.folder || what || begin
    # Que ce soit une ouverture "direct" (comme le manuel, ou le dossier
    # bin) ou l'ouverture d'un élément du tutoriel, il faut toujours que
    # COMMAND.folder soit défini
    error "Il faut indiquer ce qu'il faut ouvrir…"
    return
  end

  # p.e. 'o' => 'operations'
  what = SHORT_SUJET_TO_REAL_SUJET[what] || what

  case what
  when 'folder'
    # Ouverture du dossier du tutoriel dans le finder
    `open -a Finder "#{current_folder}"`
  when 'operations'
    require_module('operations/operations')
    exec_open_operations_file
  when 'scrivener'
    if edition
      scrivener_project.open
    else
      res = scrivener_project.duplique_and_open
      puts "(ajoute -e/--edit pour éditer le projet préparé.)"
      return res
    end
  when 'titre'
    if File.exists?(titre_path)
      `open -a Scrivener "#{titre_path}"`
      return true
    else
      unless COMMAND.options[:quiet]
        error "Le fichier Titre.scriv est introuvable…\n#{titre_path}"
      end
      return false
    end
  when 'vignette'
    if edition
      if File.exists?(vignette_gimp)
        `open -a Gimp "#{vignette_gimp}"`
        notice "Modifie le titre puis export en jpg sous le nom 'Vignette.jpg'"
      else
        error "Le fichier vignette est introuvable\n#{vignette_gimp}"
      end
    else
      # On ouvre simplement la vignette
      `open "#{vignette_jpeg}"`
      puts "(ajoute -e/--edit pour éditer la vignette et la produire)"
    end
  when 'voice'
    if edition
      # Éditer, c'est-à-dire modifier, dans Audacity
      edit_voice_file
    elsif COMMAND.options[:record]
      # Enregistrer la voix
      record_voice
    else
      if File.exists?(record_voice_path)
        `open "#{record_voice_path}"`
      end
    end
  when 'montage'
    montageFile = existingMontageFile
    unless montageFile
      choix = getChar("Dois-je initier un projet Screenflow (s) ou Premiere (p) ?")
      choix || return
      case choix.upcase
      when 'S'
        # => montage Screenflow
        src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel','gabarit.screenflow')
        FileUtils.copy_entry(src, screenflow_path)
        montageFile = screenflow_path
      when 'P'
        # => montage Adobe Premiere
        src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel','gabarit.prproj')
        FileUtils.copy_entry(src, premiere_path)
        montageFile = premiere_path
      else
        return error "Je ne connais pas ce type de montage ('#{choix}')…"
      end
    end
    if montageFile
      notice "Bon montage ! 👍"
      notice "Tu pourras prendre des notes de montage dans le fichier 'Notes-montages.md'"
      `open "#{montageFile}"`
    end
  else
    ViteFait.exec_open(what)
  end
end

# Retourne le fichier montage s'il existe, rien sinon
def existingMontageFile
  if File.exists?(screenflow_path) && File.exists?(premiere_path)
    choix = getChar("Veux-tu ouvrir le montage Screenflow (s) ou le montage première (p) ?")
    case choix.upcase
    when 'S' then return screenflow_path
    when 'P' then return premiere_path
    else return # rien = renoncement
    end
  elsif File.exists?(screenflow_path)
    return screenflow_path
  elsif File.exists?(premiere_path)
    return premiere_path
  end
  puts "Recherche avec : #{folder}/*.screenflow"
  screenflowFile = Dir["#{folder}/*.screenflow"].first
  return screenflowFile if screenflowFile
  premierFile = Dir("#{folder}/*.prproj").first
  return premierFile if premierFile
end

class << self
  def exec_open what
    case what
    when 'folder_captures', 'folder-captures', 'captures'
      open_folder_captures
    when 'backup'
      open_folder_backup
    else
      folder = COMMAND.folder
      case folder
      when 'dev'
        # Pour ouvrir le dossier bin dans Atom
        `open -a Atom "#{BIN_FOLDER}"`
      when 'bin'
        `open -a Finder "#{BIN_FOLDER}"`
      when 'disk'
        `open -a Finder "#{VITEFAIT_FOLDER_ON_DISK}"`
      when 'laptop'
        `open -a Finder "#{VITEFAIT_FOLDER_ON_LAPTOP}"`
      when 'backup'
        open_folder_backup
      else
        if folder.nil? && COMMAND.options[:help]
          puts "Vous voulez de l'aide sur la commande ouvrir ?"
          goto_manuel('commandesopen')
        elsif folder && new(folder).exists? && what.nil?
          new(folder).open_in_finder(COMMAND.params[:version])
        else
          error "🖐  Je ne sais pas ouvrir '#{what}'."
        end
      end
    end
  end


  def open_folder_backup
    IO.check_existence(VITEFAIT_BACKUP_FOLDER, {interactive:true}) || return
    notice "* Ouverture du dossier des backups dans le Finder…"
    `open -a Finder #{VITEFAIT_BACKUP_FOLDER}`
  end
end #<< self

end #/ViteFait
