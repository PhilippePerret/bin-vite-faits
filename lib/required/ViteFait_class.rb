# encoding: UTF-8
def vitefait
  @vitefait ||= ViteFait.new(COMMAND.folder)
end

class ViteFait


  # Initialisation de la commande
  def self.init

  end

  def self.finish
    data.update
  end

  # Méthode pour afficher le nom du tutoriel courant, s'il existe
  def self.show_current_name
    if current_tutoriel
      notice "Le tutoriel courant '#{current_tutoriel}'"
    else
      notice "Aucun tutoriel courant."
    end
  end

  class << self
    def current_tutoriel
      @current_tutoriel ||= begin
        if data.last_tutoriel && Time.now.to_i < data.last_tutoriel_time + 3600
          data.last_tutoriel
        end
      end
    end
    def current_tutoriel=(value)
      @current_tutoriel = value
    end
  end #/<< self

  def self.require_module module_name
    require File.join(FOLDER_MODULES,module_name)
  end

  def self.open_help
    if COMMAND.options[:edit] || !File.exists?(VITEFAIT_MANUAL_PATH)
      `open -a Typora "#{VITEFAIT_HELP_PATH}"`
    else
      `open "#{VITEFAIT_MANUAL_PATH}"`
    end
  end

  # Ouvrir quelque chose (dans le finder)
  def self.open folder
    require_module('open')
    exec_open(folder)
  end

  # Ouvrir le dossier des captures (qui doit être défini dans les
  # constantes constants.rb)
  def self.open_folder_captures
    if File.exists?(FOLDER_CAPTURES)
      `open -a Finder "#{FOLDER_CAPTURES}"`
    else
      error "Le dossier capture est introuvable (#{FOLDER_CAPTURES})"
      error "Il faut définir son path dans constants.rb (FOLDER_CAPTURES)"
    end
  end

  # Méthode qui prend le dernier enregistrement effectué dans le
  # dossier captures et le déplace vers +path+
  # +path+ doit être le chemin complet, avec le nom du fichier,
  # qui changera donc le nom actuel du fichier
  #
  # Comme la capture peut être longue à être enregistrée, on
  # attend toujours sur le fichier. Et par mesure de précaution,
  # on ne prend jamais un fichier vieux de plus de 30 secondes.
  #
  # @return TRUE
  #         en cas de succès
  #
  def self.move_last_capture_in(dest_path)
    dest_path || (return error "Le fichier destination devrait être défini…")

    # On va boucler jusqu'à trouver un candidat valide
    candidat = nil
    start_time  = Time.now.to_i
    timeout     = start_time + 60 # on attend 30 secondes maximum

    while candidat.nil? && Time.now.to_i < timeout

      # On cherche le candidat le plus récent
      movs = Dir["#{FOLDER_CAPTURES}/*.mov"].each do |file|
        mtime = File.stat(file).mtime.to_i
        mtime > start_time - 30 || next
        if candidat.nil? || mtime > candidat.time
          candidat = {path:file, time:mtime}
        end
      end

      if candidat.nil?
        puts "Pas encore de vidéo adéquate…"
        sleep 5
      end
    end # /fin de la boucle jusqu'à trouver notre bonheur

    if candidat.nil?
      # Aucune vidéo convenable n'a été trouvée dans la dernière
      # minute.
      error "Aucun fichier capture adéquat (*) dans le dossier des captures (**)\n(*) pour être adéquat, la capture doit avoir été produite dans les 30 dernières secondes.\n(**) dossier #{FOLDER_CAPTURES}"
    else
      # OK, on a trouvé une vidéo
      # On peut déplacer le fichier
      FileUtils.move(candidat[:path], dest_path)
      if File.exists?(dest_path)
        return true
      else
        return(error("Bizarrement, le fichier .mov (*) n'a pas pu être déplacé vers la destination voulue (**)\n(*) #{last_mov}\n(**) #{dest_path}"))
      end
    end
  end

  # Retourne la liste complète des tutoriels vite-faits
  def self.list
    @@list ||= begin
      require_module('list')
      List.new
    end
  end

  # Recherche le nom le plus proche de +name+
  def self.get_nearer_from_name(name)
    self.list.get_nearer_from_name(name)
  end
  # Pour lancer les assistants de création ou d'accompagnement
  # On parle ici de l'assistant général, permettant de construire tout
  # le tutoriel aussi bien que les assistants qui permettent d'accompagner
  # l'enregistrement de la voix ou de lire les opérations à exécuter.
  def self.assistant
    case COMMAND.params[:pour]
    when 'operations'
      vitefait.is_required && vitefait.create_file_operations
    when 'capture'
      vitefait.is_required && vitefait.record_operations
    when 'titre', 'title'
      vitefait.is_required && vitefait.record_titre
    when 'voice', 'voix', 'texte'
      vitefait.name_is_required || vitefait.assistant_voix_finale
    else
      require_module('creation_assistant')
      create_with_assistant
    end
  end

  # Pour poser une question et produire une erreur en cas d'autre réponse
  # que 'y'
  # Pour fonctionner, la méthode (ou la sous-méthode) qui utilise cette
  # formule doit se terminer par :
  #     rescue NotAnError => e
  #       e.puts_error_if_message
  #     end
  def self.yesOrStop(question)
    yesNo(question) || raise(NotAnError.new)
  end

  class << self
    # Chemin d'accès au son de la machine à écrire
    def machine_a_ecrire_path
      @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aac')
    end
  end #/ << self
end
