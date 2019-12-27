# encoding: UTF-8
def vitefait
  @vitefait ||= ViteFait.new(COMMAND.folder)
end

class ViteFait

  class << self
    def goto_manuel anchor
      `open -a #{DEFAULT_BROWSER} "http://localhost/#{VITEFAIT_HTML_MANUAL_URI}##{anchor}"`
    end
    alias :goto_manual :goto_manuel
  end #/<< self

  # Initialisation de la commande
  def self.init
    require_module('check_init')
    check_init
  end

  # Pour faire un test ou des tests de code
  # Taper `vite-faits test` en console
  def self.test
    # Mettre ici du code à essayer
    if vitefait.video_sur_youtube?
      notice "La vidéo a été trouvée sur YouTube"
    else
      error "La vidéo n'existe pas sur YouTube"
    end
  end

  def self.finish
    data.update
    check_before_finish
  end

  # Pour aider à la conception
  def self.aide_conception
    require_module('conception')
    tuto_name = COMMAND.folder ||= 'tuto-demo'
    @vitefait = nil
    vitefait.conception.display
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
    if COMMAND.options[:edit] || !File.exists?(VITEFAIT_PDF_MANUAL_PATH)
      `open -a Typora "#{VITEFAIT_MARKDOWN_MANUAL_PATH}"`
    else
      `open "#{VITEFAIT_PDF_MANUAL_PATH}"`
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
    timeout     = start_time + 60 # on attend au maximum une minute

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
        puts "J'attends sur la vidéo…"
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
    if COMMAND.options[:help]
      return goto_manual('commandesassistant')
    end
    case COMMAND.params[:pour]
    when 'operations'
      vitefait.is_required && vitefait.create_file_operations
    when 'capture'
      vitefait.is_required && vitefait.record_operations
    when 'titre', 'title'
      vitefait.is_required && vitefait.record_titre
    when 'voice', 'voix', 'texte'
      vitefait.name_is_required || vitefait.record_voice
    else
      require_module('assistant')
      create_with_assistant
    end
  end

  # Pour procéder à la copie d'un fichier Scrivener, en sachant que
  # par le bash, il faut copier le fichier .scriv et modifier le
  # nom du fichier .scrivx dans le paquet
  def self.scrivener_copy(src, dst)
    # FileUtils.cp_r(src, dst)
    FileUtils.copy_entry(src, dst)
    src_x = File.join(dst,File.basename(src)+'x')
    dst_x = File.join(dst,"#{File.basename(dst,File.extname(dst))}.scrivx")
    FileUtils.move(src_x,dst_x)
  end

  class << self
    # Chemin d'accès au son de la machine à écrire
    def machine_a_ecrire_path
      @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aac')
    end
  end #/ << self
end
