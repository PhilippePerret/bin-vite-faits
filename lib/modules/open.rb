# encoding: UTF-8
class ViteFait
class << self
  def exec_open what
    case COMMAND.folder
    when 'bin', 'dev'
      # Pour ouvrir le dossier bin dans Atom
      `open -a Atom "#{BIN_FOLDER}"`
    when 'disk'
      `open -a Finder "#{VITEFAIT_FOLDER_ON_DISK}"`
    when 'laptop'
      `open -a Finder "#{VITEFAIT_FOLDER_ON_LAPTOP}"`
    else
      if new(folder).exists?
        new(folder).open_in_finder(COMMAND.params[:version])
      else
        error "🖐  Je ne sais pas ouvrir '#{folder}'."
      end
    end
  end
end #<< self
# ---------------------------------------------------------------------
#   INSTANCE
# ---------------------------------------------------------------------
def exec_open what
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
    require_module('operations')
    exec_open_operations_file
  when 'scrivener'
    if COMMAND.options[:edit]
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
    if COMMAND.options[:edit]
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
    if COMMAND.options[:edit]
      # Éditer, c'est-à-dire modifier, dans Audacity
      edit_voice_file
    elsif COMMAND.options[:record]
      # Enregistrer la voix
      record_voice
    else
      if File.exists?(vocal_capture_path)
        `open "#{vocal_capture_path}"`
      end
    end
  when 'montage'
    if File.exists?(screenflow_path)
      `open -a ScreenFlow "#{screenflow_path}"`
    elsif File.exists?(premiere_path)
      `open "#{premiere_path}"`
    else
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
  else
    ViteFait.exec_open
  end
end
end #/ViteFait
