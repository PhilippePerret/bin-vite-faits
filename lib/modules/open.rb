# encoding: UTF-8
class ViteFait
class << self
  def exec_open folder
    if folder.nil?
      error "Il faut indiquer ce qu'il faut ouvrir…"
    else
      case folder
      when 'operations'
        # TODO Ouvrir en lecture ou en édition
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
  end
end #<< self
end #/ViteFait
