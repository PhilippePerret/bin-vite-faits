# encoding: UTF-8
class ViteFait
# ---------------------------------------------------------------------
#   INSTANCE
# ---------------------------------------------------------------------
def exec_open what, edition = nil

  if edition === nil
    edition = !!COMMAND.options[:edit]
  end

  COMMAND.folder || begin
    # Que ce soit une ouverture "direct" (comme le manuel, ou le dossier
    # bin) ou l'ouverture d'un élément du tutoriel, il faut toujours que
    # COMMAND.folder soit défini
    error "Il faut indiquer ce qu'il faut ouvrir…"
    return
  end

  # p.e. 'o' => 'operations'
  what = SHORT_SUJET_TO_REAL_SUJET[what] || what

  case what
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
    unless File.exists?(screenflow_path) ||  File.exists?(premiere_path)
      choix = getChar("Dois-je initier un projet Screenflow (s) ou Premiere (p) ?")
      choix || return
      case choix.upcase
      when 'S'
        # => montage Screenflow
        src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel','gabarit.screenflow')
        FileUtils.copy_entry(src, screenflow_path)
      when 'P'
        # => montage Adobe Premiere
        src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel','gabarit.prproj')
        FileUtils.copy_entry(src, premiere_path)
      else
        return error "Je ne connais pas ce type de montage ('#{choix}')…"
      end
    end
    notice "Bon montage ! 👍"
    if File.exists?(screenflow_path)
      `open -a ScreenFlow "#{screenflow_path}"`
    elsif File.exists?(premiere_path)
      `open "#{premiere_path}"`
    end
  else
    ViteFait.exec_open(what)
  end
end

class << self
  def exec_open what
    case what
    when 'folder_captures', 'folder-captures'
      open_folder_captures
    else
      folder = COMMAND.folder
      case folder
      when 'bin', 'dev'
        # Pour ouvrir le dossier bin dans Atom
        `open -a Atom "#{BIN_FOLDER}"`
      when 'disk'
        `open -a Finder "#{VITEFAIT_FOLDER_ON_DISK}"`
      when 'laptop'
        `open -a Finder "#{VITEFAIT_FOLDER_ON_LAPTOP}"`
      else
        if folder.nil? && COMMAND.options[:help]
          puts "Vous voulez de l'aide sur la commande ouvrir ?"
          goto_manuel('commandesopen')
        elsif folder && new(folder).exists?
          new(folder).open_in_finder(COMMAND.params[:version])
        else
          error "🖐  Je ne sais pas ouvrir '#{folder}'."
        end
      end
    end
  end
end #<< self

end #/ViteFait
