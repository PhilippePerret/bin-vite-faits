# encoding: UTF-8
def vitefait
  @vitefait ||= ViteFait.new(COMMAND.folder)
end

class ViteFait

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

  # ---------------------------------------------------------------------
  #
  #   INSTANCE
  #
  # ---------------------------------------------------------------------

  # Le dossier de travail, donc sur l'ordinateur
  # (par opposition au dossier de conservation qui se trouve sur le
  # disque appelé MacOSCatalina)
  attr_accessor :work_folder

  def initialize folder
    self.work_folder = folder
    check_tutoriel
  end

  # ---------------------------------------------------------------------
  #   Les méthodes test et d'état
  # ---------------------------------------------------------------------

  # À l'instanciation du tutoriel, on vérifie s'il est
  # valide. Noter qu'il peut, ici, ne pas encore exister
  def check_tutoriel
    @is_valid = true

    if name.nil?
      @is_valid = false
      return
    end

    # Le dossier du tutoriel ne doit pas être trouvé à
    # deux endroits différents
    lieux = []
    folder_en_attente?    && lieux << {key: :attente}
    folder_en_chantier?   && lieux << {key: :chantier}
    en_chantier_on_disk?  && lieux << {key: :chantierd}
    folder_completed?     && lieux << {key: :completed}
    folder_published?     && lieux << {key: :published}

    if lieux.count > 1
      error "\n\nProblème avec ce tutoriel qu'on trouve dans plusieurs lieux (#{lieux.count})…"
      error "Il ne faudrait garder qu'un seul de ces lieux :\n\n"
      lieux = lieux.sort_by do |dlieu|
        dlieu[:path]      = send("#{dlieu[:key]}_folder_path")
        dlieu[:last_time] = File.stat(dlieu[:path]).mtime
      end.reverse
      lieux.each do |dlieu|
        puts "\tDossier :#{(dlieu[:key]).to_s.ljust(12)} : #{dlieu[:last_time]}"
      end
      puts "\n\n(note : je les ai classés du plus récent au plus ancien,\ndonc le plus logique serait de garder le premier)"
      error "\n\nPour corriger ce problème, jouer la commande :\n\n\tvite-faits keep_only #{name} lieu=<lieu>\n\n(où lieu est 'attente', 'chantier', 'chantierd', 'completed' ou 'published')"
      @is_valid = false
    end

  end

  def name_is_required
    if self.defined?
      return false
    else
      error "Il faut définir quel vite-fait utiliser en indiquant le nom de son dossier en second argument."
      return true
    end
  end

  # Méthode utilisée au début, pour s'assurer qu'un tutoriel peut
  # utiliser une certaine commande. Ici, il faut que son dossier
  # existe, qu'il soit valide (un seul lieu).
  def is_required
    name_is_required && (return false)
    if self.defined? && self.exists? && self.valid?
      return true
    elsif self.defined?
      candidat = self.class.get_nearer_from_name(name)
      if candidat.nil?
        return error "Je n'ai trouvé aucun tutoriel de ce nom ou proche de ce nom. Je dois renoncer.\n\n"
      end
      yesNo("Je n'ai pas trouvé ce tutoriel…\nS'agit-il du tutoriel '#{candidat[:name]}' ? (si c'est un nouveau, tape 'n')") || return
      instance_variables.each do |prop|
        instance_variable_set("#{prop}", nil)
      end
      COMMAND.folder = self.work_folder = @name = candidat[:name]
      @vitefait = nil
      check_tutoriel
      return true
    else
      error "Un tutoriel existant et valide est requis pour cette opération.\nJe dois m'arrêter là."
    end
  end


  # ---------------------------------------------------------------------
  #   Les actions
  # ---------------------------------------------------------------------


  # ---
  #   Méthodes de création
  # ---

  # Pour créer le vite-fait
  def create(nomessage = true)
    require_module('create_vite_fait')
    exec_create(nomessage)
  end

  # ---
  #   Pour les opérations
  # ---

  # Pour créer le fichier des opérations de façon assistées
  def create_file_operations
    require_module('operations_assistant')
    assistant_creation_file
  end

  # Pour récupérer les opérations définies
  # Attention : il faut avoir vérifié avant que le fichier existait
  # à l'aide de `operations_are_defined?`
  def get_operations
    operations_are_defined? || return
    YAML.load_file(operations_path).to_sym
  end


  # Pour lancer la lecture des opérations définies
  def record_operations
    require_module('assistant/record_operations')
    exec
  rescue NotAnError => e
    e.puts_error_if_message
    error "OK, on abandonne.\n\n"
  end

  # Retourne true si le fichier capture des
  # opérations existe, false dans le cas contraire.
  # Si +required+ est true, produit une erreur en
  # cas d'absence
  def operations_are_recorded?(required = false, nomessage = true)
    existe = src_path(noalert = true) && File.exists?(src_path)
    if required && !existe
      error "Le fichier Operations/capture.mov devrait exister.\nPour le créer, tu peux utiliser l'assistant :\n\tvite-faits assistant #{name} pour=capture"
    end
    if existe && !nomessage
      notice "--- La capture des opérations a été opérée."
    end
    return existe
  end

  # Retourne TRUE s'il existe un fichier des opérations à lire
  # Ce fichier s'appelle 'operations.yaml' et se trouve à la
  # racine du dossier du tutoriel
  # Mettre +required+ à true pour générer une alerte ne cas d'absence
  # avec le message d'aide. Utilisation :
  #   operations_are_defined?(true) || return
  def operations_are_defined?(required = false, nomessage = true)
    existe = File.exists?(operations_path)
    if !existe && required
      return error "Le fichier des opérations n'existe pas. Pour le créer, jouer :\n\n\tvite-faits assistant #{name} pour=operations\n\n"
    end
    if existe && !nomessage
      notice "--- Les opérations sont définies."
    end
    return existe
  end

  # ---
  #   Méthodes d'écriture
  # ---

  # Pour afficher l'état du tutoriel
  def write_rapport
    require_module('report')
    exec_print_report
  end

  # ---
  #   Méthodes d'ouverture
  # ---


  # Ouvrir le dossier du tutoriel où qu'il soit enregistré
  def open_in_finder(version = nil)
    if version.nil?
      dcurrent = current_best_folder
      notice "Version ouverte : #{dcurrent[:hname]}"
      `open -a Finder "#{dcurrent[:path]}"`
    else
      # <= Une version précise est demandée
      # => On essaie de l'ouvrir si elle existe
      open_if_exists(send("#{version}_folder_path"), version2hname(version))
    end
  end

  def open_current_folder
    if File.exists?(current_folder)
      `open -a Finder "#{current_folder}"`
    else
      error "Impossible d'ouvrir le dossier courant (*), il n'existe pas…\n(*) #{current_folder}"
    end
  end

  # Pour ouvrir le projet scrivener du tutoriel
  def open_scrivener_project
    project_scrivener_exists?(required=true) || return
    `open -a Scrivener "#{scriv_file_path}"`
  end

  # Pour ouvrir le fichier des opérations
  def open_operations_file
    operations_are_defined?(required=true) || return
    system('vim', operations_path)
  end

  # Pour ouvrir le fichier screenflow ou Premiere
  def open_montage
    if File.exists?(screenflow_path)
      `open -a ScreenFlow "#{screenflow_path}"`
    elsif File.exists?(premiere_path)
      `open "#{premiere_path}"`
    else
      error "🖐  Impossible de trouver un fichier de montage à ouvrir…"
      return
    end
    notice "Bon montage ! 👍"
  end

  def open_if_exists folder, version
    if File.exists?(folder)
      notice "Ouverture de la version #{version}"
      `open -a Finder "#{folder}"`
    else
      error "La version #{version} n'existe pas."
      versions_names = versions(:hname)
      la_version = versions_names.count > 1 ? 'les versions : ' : 'la version'
      notice "Ce projet possède seulement #{la_version} #{versions_names.join(', ')}."
    end
  end

  # Ouvre le fichier Scrivener qui va permettre de jouer les
  # opération.
  def open_scrivener_file
    if File.exists?(scriv_file_path)
      `open -a Scrivener "#{scriv_file_path}"`
    else
      error "Impossible d'ouvrir le fichier Scrivener, il n'existe pas.\nà : #{scriv_file_path}"
    end
  end

  def open_vignette
    if File.exists?(vignette_gimp)
      `open -a Gimp "#{vignette_gimp}"`
      notice "Modifie le titre puis export en jpg sous le nom 'Vignette.jpg'"
    else
      error "Le fichier vignette est introuvable\n#{vignette_gimp}"
    end
  end

  def open_titre(nomessage = true)
    if File.exists?(titre_path)
      `open -a Scrivener "#{titre_path}"`
    else
      error "Le fichier Titre.scriv est introuvable…\n#{titre_path}"
    end
  end

  def record_titre(nomessage=true)
    require_module('assistant/record_titre')
    exec
  rescue NotAnError => e
    e.puts_error_if_message
    error "J'abandonne…"
  end

  # ---
  #   Méthodes de conversion
  # ---

  # Pour transformer le fichier capture en vidéo mp4
  def capture_to_mp4
    operations_are_recorded?(required=true) || return
    require_module('capture_to_mp4')
    exec_capture_to_mp4
  end

  # Méthode de transformation du titre en fichier mp4
  def titre_to_mp4
    require_module('titre_to_mp4')
    exec_titre_to_mp4
  end


  # Assemble la vidéo complète
  # cf. le module 'assemblage.rb'
  def assemble nomessage = true
    require_module('assemblage')
    exec_assemble(nomessage)
  rescue NotAnError => e
    e.puts_error_if_message
  end

  # Assemble la vidéo de la capture et la voix
  def assemble_capture nomessage = true
    require_module('assemblage_capture')
    exec_assemble_capture(nomessage)
  end

  # Ne conserve qu'un seul dossier
  # C'est le paramètre :lieu qui définit le lieu
  def keep_only_folder
    require_module('keep_only_folder')
    exec_keep_only_folder
  end

  # Méthode appelée pour déplacer le tutoriel
  def move
    require_module('move')
    exec_move
  end

  # ---
  #   Autres méthodes
  # ---

  # Pour assister la fabrication finale de la voix du tutoriel
  # en affichant le texte défini dans le fichier des opérations.
  def assistant_voix_finale
    require_module('assistant/record_voice')
    exec
  rescue NotAnError => e
    e.puts_error_if_message
    error "Nous abandonnons."
  end

  # True s'il existe un fichier vocal séparé
  def voice_capture_exists?(required=false,nomessage=true)
    existe = File.exists?(vocal_capture_path)
    if !existe && required
      error "Le fichier voix est requis. Pour le produire de façon assistée, utiliser :\n\n\tvite-faits assistant #{name} pour=voix\n\n"
    elsif existe && !nomessage
      notice "--- Voix capturée."
    end
    return existe
  end



  # Retourne la table des versions existantes
  # Si +key+ est définie, on retourne la liste de ces clés. Par exemple :hname
  # pour obtenir les noms des versions seulement
  def versions(key = nil)
    @versions = []
    folder_en_chantier?          && @versions << :chantier
    folder_completed?            && @versions << :complete
    en_chantier_on_disk?  && @versions << :chantierd
    folder_en_attente?           && @versions << :waiting
    if key.nil?
      @versions
    else
      @versions.collect{|version_id| versionAbs(version_id)[key]}
    end
  end

  # Retourne les informations absolues de la version d'identifiant
  # version_id (qui peut être :chantier, :complete, :waiting ou chantierd)
  def versionAbs version_id
    DATA_LIEUX[version_id.to_sym]
  end
  def version2hname version
    dversion = versionAbs(version)
    if dversion.nil?
      error "Impossible de trouver le lieu #{version}…"
    else
      dversion[:hname]
    end
  end

  # Un tutoriel peut être placé à 4 endroits différents :
  # Cette méthode retourne le "meilleur" endroit, c'est-à-dire l'endroit où
  # l'on a des chances de rencontrer le dossier le plus à jour
  def current_best_folder
    path, name =
      if folder_en_chantier?
        [chantier_folder_path, version2hname(:chantier)]
      elsif folder_completed?
        [completed_folder_path, version2hname(:completed)]
      elsif en_chantier_on_disk?
        [chantierd_folder_path, version2hname(:chantierd)]
      elsif folder_en_attente?
        [attente_folder_path, version2hname(:waiting)]
      end
    {path:path, hname:name}
  end

  def informations
    @informations ||= begin
      require_module('informations')
      Informations.new(self)
    end
  end
  alias :infos :informations

  # Méthode appelée pour uploader la vidéo sur YouTube
  # En fait, ça ouvre l'interface pour le faire + le dossier contenant
  # la vidéo à uploader
  def upload
    notice "\n\nJ'ouvre le dossier contenant la vidéo finale\n+ Safari sur la page d'upload de la chaine."
    `open -a Safari "https://studio.youtube.com/channel/UCWuW11zTGdNfoChranzBMxQ/videos/upload?d=ud&filter=%5B%5D&sort=%7B%22columnType%22%3A%22date%22%2C%22sortOrder%22%3A%22DESCENDING%22%7D"`
    notice "Pour s'identifier, utiliser le compte Yahoo normal avec le mot de passe normal."
    if File.exists?(exports_folder)
      `open -a Finder "#{exports_folder}"`
    else
      error "Impossible de trouver le dossier des exports,\nje ne peux pas vous présenter la vidéo à uploader\n#{exports_folder}"
    end
  end

  # ---------------------------------------------------------------------
  #   MÉTHODES D'ÉTATS
  # ---------------------------------------------------------------------

  # Retourne TRUE si le tutoriel est valide, c'est-à-dire,
  # principalement, s'il ne se trouve que dans un seul dossier,
  # pas deux.
  def valid?
    !!@is_valid
  end

  # TRUE si le tutoriel définit son nom
  # (et juste son nom, pas son existence, qui doit être
  #  checkée avec exists?)
  def defined?
    self.work_folder != nil
  end

  def exists?
    lieu && File.exists?(current_folder)
  end

  # True si le titre, le titre anglais et la description du tutoriel
  # sont définis
  def infos_defined?(nomessage = true)
    vrai = !!(titre && titre_en && description)
    if !nomessage && vrai
      notice "--- Informations tutorielles données."
    end
    return vrai
  end

  # Lieu où on trouve ce tutoriel
  #
  # Attention : doit vraiment retourner NIL en cas d'absence, car c'est
  # comme ça qu'on sait si le projet a été créé.
  def lieu
    @lieu ||= getLieu
  end
  def getLieu
    folder_en_attente?    && (return :attente)
    folder_en_chantier?   && (return :chantier)
    en_chantier_on_disk?  && (return :chantierd)
    folder_completed?     && (return :complected)
    folder_published?     && (return :published)
    return nil
  end

  # Le lieu, en valeur humaine
  def hlieu
    @hlieu ||= infos_lieu[:hname]
  end

  def infos_lieu
    @infos_lieu ||= DATA_LIEUX[lieu]
  end

  def folder_en_attente?
    File.exists?(attente_folder_path)
  end
  def folder_en_chantier?
    File.exists?(chantier_folder_path)
  end
  def en_chantier_on_disk?
    File.exists?(chantierd_folder_path)
  end
  def folder_completed?
    File.exists?(completed_folder_path)
  end
  def folder_published?
    File.exists?(published_folder_path)
  end

  def mp4_capture_exists?(required = false, nomessage=true)
    existe = File.exists?(mp4_path)
    if !existe && required
      error "Impossible de trouver le fichier mp4 de la capture…\nVous devez au préalable :\n\n\t- Enregistrer le fichier .mov de la capture\n\n\t- le convertir en fichier .mp4\n\n"
    elsif existe && !nomessage
      notice "--- Fichier capture.mp4 préparé."
    end
    existe
  end

  # Retourne TRUE s'il existe un fichier scrivener pour
  # ce tutoriel.
  # Mettre +required+ à true pour générer une alerte en cas d'absence
  # du fichier. Meilleure tournure :
  #   project_scrivener_exists?(true) || return
  #
  def project_scrivener_exists?(required = false)
    existe = File.exists?(scriv_file_path)
    if !existe && required
      error "Impossible de trouver le fichier Project Scrivener du tutoriel…\nà : #{scriv_file_path}"
    end
    existe
  end

  # ---------------------------------------------------------------------
  #   Méthodes pour se rendre sur les lieux
  # ---------------------------------------------------------------------
  def chaine_youtube
    `open -a Safari "#{url_chaine}"`
    sleep 2
    `open -a Terminal`
  end

  def groupe_facebook
    `open -a Firefox "#{url_groupe_facebook}"`
  end

  def forum_scrivener
    `open -a Safari "#{url_forum_scrivener}"`
  end

  # Pour faire l'annonce du nouveau tutoriel
  def annonce(pour = nil)
    require_module('annonces')
    exec_annonce(pour)
  end

  def url_chaine
    @url_chaine ||= 'https://www.youtube.com/channel/UCWuW11zTGdNfoChranzBMxQ'
  end

  def url_groupe_facebook
    @url_groupe_facebook ||= 'https://www.facebook.com/groups/1893652697386562/'
  end

  def url_forum_scrivener
    @url_forum_scrivener ||= 'https://www.literatureandlatte.com/forum/viewtopic.php?f=19&t=53105&hilit=tutoriels'
  end

  def post_forum_scrivener
    require_module('annonce_FB')
    exec_annonce_FB
  end

  # ---------------------------------------------------------------------
  #   Méthodes fonctionnelles
  # ---------------------------------------------------------------------


  # Construit un dossier s'il n'existe pas
  def mkdirs_if_not_exist liste
    liste.each do |pth|
      Dir.mkdir(pth)
      notice "--> CREATE FOLDER #{relative_pathof(pth)} 👍"
    end
  end
  # Détruit un fichier s'il existe
  def unlink_if_exist liste
    liste.each do |pth|
      if File.exists?(pth)
        File.unlink(pth)
        notice "---> Destruction de ./#{relative_pathof(pth)}"
      end
    end
  end

  def line_exists_file path, name
    if path && File.exists?(path)
      notice "    - fichier #{name}".ljust(32,'.') + ' oui'
    else
      error "    - fichier #{name}".ljust(32,'.') + ' non'
    end
  end

  def require_module module_name
    self.class.require_module(module_name)
  end

  # ---------------------------------------------------------------------
  #   Les propriétés volatiles
  # ---------------------------------------------------------------------

  def name
    @name ||= work_folder
  end

  # Les données dans le fichier information du tutoriel (définies ou non,
  # mais ça renvoie toujours une donnée)
  def titre
    @titre ||= informations[:titre]
  end
  def titre_en
    @titre_en ||= informations[:titre_en]
  end
  def youtube_id
    @youtube_id ||= informations[:youtube_id]
  end
  def description
    @description ||= informations[:description]
  end



  # ---------------------------------------------------------------------
  #   Paths
  # ---------------------------------------------------------------------

  # Le fichier .mov de la capture des opérations
  # Noter que si on trouve un fichier .mov, il sera renommé par le
  # nom par défaut, qui est "<nom-dossier-tuto>.mov"
  def src_path(no_alert = false)
    @src_path ||= begin
      if File.exists?(default_source_path)
        @src_name = default_source_fname
        default_source_path
      else
        src_name = COMMAND.params[:name] || get_first_mov_file()
        if src_name.nil?
          unless no_alert
            error "🖐  Je ne trouve aucun fichier .mov à traiter.\nSi le fichier est dans une autre extension, préciser explicement son nom avec :\n\t`vite-faits capture_to_mp4 #{name} name=nom_du_fichier.ext`."
          end
          nil
        else
          @src_name = File.basename(src_name)
          pathof(src_name)
        end
      end
    end
  end

  def get_first_mov_file
    Dir["#{operations_folder}/*.mov"].each do |pth|
      fname = File.basename(pth)
      if fname === default_source_fname
        return default_source_fname
      elsif fname.downcase != 'titre.mov'
        # On va renommer ce fichier pour qu'il porte le bon nom
        FileUtils.move(pth, default_source_path)
        return default_source_fname
      end
    end
    return nil # non trouvé
  end

  def src_name; @src_name end

  def default_source_fname
    @default_source_fname ||= "capture.mov"
  end
  def default_source_path
    @default_source_path ||= File.join(operations_folder, default_source_fname)
  end

  # Chemin d'accès au fichier contenant peut-être les opérations
  # à dire tout haut pour créer plus facilement le programme
  def operations_path
    @operations_path ||= File.join(operations_folder,'operations.yaml')
  end

  def mp4_path
    @mp4_path ||= File.join(operations_folder, "capture.mp4")
  end
  def mp4_cropped_path
    @mp4_cropped_path ||= File.join(operations_folder, "capture-cropped.mp4")
  end
  def ts_path
    @ts_path ||= File.join(operations_folder, "capture.ts")
  end
  def completed_path
    @completed_path ||= File.join(exports_folder, "#{name}_completed.mp4")
  end
  def scriv_file_path
    @scriv_file_path ||= pathof(scriv_file_name)
  end
  def scriv_file_name
    @scriv_file_name ||= "#{name}.scriv"
  end
  def screenflow_path
    @screenflow_path ||= pathof("Montage.screenflow")
  end
  def premiere_path
    @premiere_path ||= pathof("Montage.prproj")
  end

  def record_titre_exists?(required = false)
    existe = titre_mov && File.exists?(titre_mov)
    if !existe && required
      error "L'enregistrement du titre devrait exister. Pour le produire, jouer :\n\n\tvite-faits assistant #{name} pour=titre\n\n"
    end
    return existe
  end

  # Éléments pour le titre
  def titre_path
    @titre_path ||= File.join(titre_folder, "Titre.scriv")
  end
  def titre_mov
    @titre_mov ||= begin
      default_path = default_titre_file_path
      unless File.exists?(default_path)
        # Il faut chercher le fichier mov dans le dossier
        current_path = Dir["#{titre_folder}/*.mov"].first
        if current_path.nil?
          default_path = nil
        else
          # On renomme le fichier
          FileUtils.move(current_path, default_path)
        end
      end
      default_path
    end
  end
  def default_titre_file_path
    @default_titre_file_path ||= File.join(titre_folder, "Titre.mov")
  end
  def titre_mp4
    @titre_mp4 ||= File.join(titre_folder, "Titre.mp4")
  end
  def titre_prov_mp4
    @titre_prov_mp4 ||= File.join(titre_folder, "Titre-prov.mp4")
  end
  def titre_ts
    @titre_ts ||= File.join(titre_folder, "Titre.ts")
  end
  # Chemin d'accès au dossier titre
  def titre_folder
    @titre_folder ||= pathof("Titre")
  end

  def operations_folder
    @operations_folder ||= pathof('Operations')
  end

  # Le fichiers final de la voix, si elle est utilisée
  # mp4 car éditable par Audacity
  def vocal_capture_path
    @vocal_capture_path ||= File.join(voice_folder,'voice.mp4')
  end
  def vocal_capture_aiff_path
    @vocal_capture_aiff_path ||= File.join(voice_folder,'voice.aiff')
  end
  # Le fichiers pour l'assemblage
  # aac car assemblable
  def voice_aac
    @voice_aac ||= File.join(voice_folder,'voice.aac')
  end
  # Le dossier voix
  def voice_folder
    @voice_folder ||= pathof('Voix')
  end


  def vignette_path
    @vignette_path ||= File.join(vignette_folder, 'Vignette.jpg')
  end
  alias :vignette_jpeg :vignette_path

  def vignette_gimp
    @vignette_gimp ||= File.join(vignette_folder, 'Vignette.xcf')
  end
  # Éléments pour la vignette
  def vignette_folder
    @vignette_folder ||= pathof("Vignette")
  end

  # Chemin d'accès au dossier des exports
  def exports_folder
    @exports_folder ||= pathof("Exports")
  end

  # Retourne le chemin relatif au fichier/dossier se trouvant dans
  # le tutoriel courant
  # Attention : maintenant, la méthode est beaucoup plus complexe et
  # retourne le chemin en fonction du lieu où se trouve le projet.
  def pathof relpath
    File.join(current_folder,relpath)
  end
  def relative_pathof(path)
    path.gsub(/^#{Regexp.escape(current_folder)}/,'.')
  end

  # Retourne le vrai dossier actuel du tutoriel
  # S'il n'est pas défini, comme c'est le cas à la création d'un nouveau
  # tutoriel, on met le lieu à 'chantier'
  def current_folder
    @current_folder || send("#{lieu}_folder_path")
  end

  # Chemin d'accès au dossier en attente (sur le disque)
  def attente_folder_path
    @attente_folder_path ||= File.join(VITEFAIT_ATTENTE_FOLDER,name)
  end

  # Chemin d'accès au dossier de travail (sur l'ordinateur)
  def chantier_folder_path
    @chantier_folder_path ||= File.join(VITEFAIT_CHANTIER_FOLDER,name)
  end


  # Chemin d'accès au dossier sur le disque
  def completed_folder_path
    @completed_folder_path ||= File.join(VITEFAIT_COMPLETED_FOLDER,name)
  end

  # Chemin d'accès au dossier de travail sur le disque
  def chantierd_folder_path
    @chantierd_folder_path ||= File.join(VITEFAIT_CHANTIERD_FOLDER,name)
  end

  # Le dossier publié du tutoriel, s'il existe sur le disque
  def published_folder_path
    @published_folder_path ||= File.join(VITEFAIT_PUBLISHED_FOLDER,name)
  end


  # ---------------------------------------------------------------------
  #   MÉTHODES FONCTIONNELLES
  # ---------------------------------------------------------------------

  def yesOrStop(question)
    self.class.yesOrStop(question)
  end

  # Si +voix_dernier est défini, on dit les dernières
  # valeurs avec cette voix (5, 4, 3, 2, 1)
  def decompte phrase, fromValue, voix_dernier = false
    puts "\n\n"
    reste = fromValue.to_i
    phrase += " " * 20 + "\r"
    while reste > 0 # on ne dit pas zéro
      # Revenir à la 20e colonne de la 4è ligne
      # print "\033[4;24H"
      # print "\033[;24H"
      s = reste > 1 ? 's' : ''
      phrase_finale = phrase % {nombre_secondes: "#{reste} seconde#{s}"}
      print phrase_finale
      # print "Ouverture du forum dans #{reste} seconde#{s}              \r"
      if voix_dernier && reste < 6
        `say -v #{voix_dernier} "#{reste}"`
        sleep 0.5
      else
        sleep 1
      end
      reste -= 1
    end
    puts "\n\n\n"
  end

  # Pour faire dire un texte
  def dire text
    `say -v Audrey "#{text}" `
  end

  class << self

    # Pour poser une question et produire une erreur en cas d'autre réponse
    # que 'y'
    # Pour fonctionner, la méthode (ou la sous-méthode) qui utilise cette
    # formule doit se terminer par :
    #     rescue NotAnError => e
    #       e.puts_error_if_message
    #     end
    def yesOrStop(question)
      yesNo(question) || raise(NotAnError.new)
    end

    def machine_a_ecrire_path
      # @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aiff')
      # @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.mp3')
      @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aac')
    end
  end #/ << self
end
