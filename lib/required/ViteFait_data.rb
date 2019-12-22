# encoding: UTF-8
=begin
  Gestion des données (fichier data.json)
=end
class ViteFait
  class << self
    def data
      @data ||= ViteFait::Data.new
    end
  end #/<< self

  class Data
    # Les données par défaut
    DEFAULT_DATA = {
      last_tutoriel: nil,       # dernier nom de tutoriel commandé
      last_command: nil,        # dernière commande jouée
      last_tutoriel_time: nil,   # dernier temps d'utilisation du tutoriel
      last_params: nil,         # Paramètres de la dernière commande
      last_options: nil         # Options de la dernière commande
    }

    def last_tutoriel; data[:last_tutoriel] end
    def last_tutoriel=(value); data[:last_tutoriel] = value end
    def last_command; data[:last_command] end
    def last_command=(value); data[:last_command] = value end
    def last_tutoriel_time; data[:last_tutoriel_time] end
    def last_tutoriel_time=(value); data[:last_tutoriel_time] = value end
    def last_params; data[:last_params] end
    def last_params=(value); data[:last_params] = value end
    def last_options; data[:last_options] end
    def last_options=(value); data[:last_options] = value end

    # On actualise des données
    # Ça se fait à chaque nouvelle commande.
    def update
      self.last_tutoriel      = ViteFait.current_tutoriel
      self.last_command       = COMMAND.action
      self.last_params        = COMMAND.params
      self.last_options       = COMMAND.options
      self.last_tutoriel_time = Time.now.to_i
      save
    end
    def save
      File.open(path,'wb'){|f| f.write(data.to_json)}
    end
    def load
      if exists?
        d = JSON.parse(File.read(path).force_encoding('utf-8'), symbolize_names:true)
      else
        DEFAULT_DATA
      end
    end

    def data
      @data ||= load
    end

    def exists?
      File.exists?(path)
    end

    def path
      @path ||= File.join(BIN_FOLDER,'lib','data.json')
    end

  end #/Data
end #/ViteFait
