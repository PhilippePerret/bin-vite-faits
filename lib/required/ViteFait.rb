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

  # Retourne la liste complète des tutoriels vite-faits
  def self.list
    @@list ||= begin
      require_module('list')
      List.new
    end
  end
  # Pour lancer les assistants de création ou d'accompagnement
  # On parle ici de l'assistant général, permettant de construire tout
  # le tutoriel aussi bien que les assistants qui permettent d'accompagner
  # l'enregistrement de la voix ou de lire les opérations à exécuter.
  def self.assistant
    case COMMAND.params[:pour]
    when 'operations'
      vitefait.name_is_required || vitefait.create_file_operations
    when 'voice', 'voix', 'texte'
      vitefait.name_is_required || vitefait.assistant_voix_finale
    else
      require_module('assistant_creation')
      create_with_assistant
    end
  end

  def self.clear
    puts "\n\n" # pour certaines méthodes
    Command.clear_terminal
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
    if self.defined? && self.exists? && self.valid?
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
  def create(nomessage = false)
    require_module('create_vite_fait')
    exec_create(nomessage)
  end

  # Pour créer le fichier des opérations de façon assistées
  def create_file_operations
    require_module('assistant_operations')
    assistant_creation_file
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
      case version.to_s
      when 'chantier', 'en_chantier'
        open_if_exists(chantier_folder_path, version2hname(:chantier))
      when 'complete', 'completed'
        open_if_exists(completed_folder_path, version2hname(:complete))
      when 'attente', 'en_attente'
        open_if_exists(attente_folder_path, version2hname(:waiting))
      when 'chantier_disk', 'en_chantier_on_disk'
        open_if_exists(chantierd_folder_path, version2hname(:chantierd))
      end
    end
  end

  # Pour ouvrir le projet scrivener du tutoriel
  def open_scrivener_project
    project_scrivener_exists?(required=true) || return
    `open -a Scrivener "#{scriv_file_path}"`
  end

  # Pour ouvrir le fichier des opérations
  def open_operations_file
    file_operations_exists?(required=true) || return
    puts "Joue la commande :\n\n\tvim \"#{operations_path}\""
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

  def open_titre(nomessage = false)
    if File.exists?(titre_path)
      `open -a Scrivener "#{titre_path}"`
      unless nomessage
        notice "Règle la largeur de la fenêtre pour avoir un beau titre\nEnregistre le titre en capturant son écriture,\nRécupère-le dans le dossier des captures,\nDéplace-le dans le dossier 'Titre' du dossier du tutoriel\nEt prépare-le si nécessaire avec la commande `vite-faits traite_titre #{name}.`"
      end
    else
      error "Le fichier Titre.scriv est introuvable…\n#{titre_path}"
    end
  end

  # ---
  #   Méthodes de conversion
  # ---

  # Pour transformer le fichier capture en vidéo mp4
  def capture_to_mp4
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
  def assemble nomessage = false
    require_module('assemblage')
    exec_assemble(nomessage)
  end

  # Assemble la vidéo de la capture et la voix
  def assemble_capture nomessage = false
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

  # Pour lancer la lecture des opérations définies
  def say_operations
    if file_operations_exists?
      require_module('assistant_operations')
      exec_lecture_operations
    else
      error "Aucune opération n'est définie. Je ne peux pas les lire pour t'accompagner."
      error "Crée le fichier des opérations ou demande à être accompagner en jouant :\n\n\tvite-faits assistant #{name} pour=operations\n\n"
    end
  end

  # Pour assister la fabrication finale de la voix du tutoriel
  # en affichant le texte défini dans le fichier des opérations.
  def assistant_voix_finale
    require_module('assistant_operations')
    exec_assistant_voix_finale
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
    DATA_LIEUX[version_id]
  end
  def version2hname version
    versionAbs(version)[:hname]
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

  # Pour "achever" le projet, c'est-à-dire le copier sur le disque et le
  # supprimer de l'ordinateur.
  def complete
    puts "\n\n*** Achèvement de #{name} demandé…"
    FileUtils.copy_entry(chantier_folder_path, completed_folder_path)
    notice "---> création du dossier '#{completed_folder_path}'"
    FileUtils.rm_rf(chantier_folder_path)
    notice "---> Destruction de '#{chantier_folder_path}'"
    notice "\n=== 👍  Achèvement terminé du tutoriel vite-fait « #{name} »"
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
    lieu != nil
  end

  # True si le titre, le titre anglais et la description du tutoriel
  # sont définis
  def infos_defined?
    !!(titre && titre_en && description)
  end

  # Lieu où on trouve ce tutoriel
  def lieu
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

  def mp4_capture_exists?(required = false)
    existe = File.exists?(mp4_path)
    if !existe && required
      error "Impossible de trouver le fichier mp4 de la capture…\nVous devez au préalable :\n\n\t- Enregistrer le fichier .mov de la capture\n\n\t- le convertir en fichier .mp4\n\n"
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

  # Retourne TRUE s'il existe un fichier des opérations à lire
  # Ce fichier s'appelle 'operations.yaml' et se trouve à la
  # racine du dossier du tutoriel
  # Mettre +required+ à true pour générer une alerte ne cas d'absence
  # avec le message d'aide. Utilisation :
  #   file_operations_exists?(true) || return
  def file_operations_exists?(required = false)
    existe = File.exists?(operations_path)
    if !existe && required
      return error "Le fichier des opérations n'existe pas. Pour le créer, consulter le mode d'emploi ou jouer :\n\n\tvite-faits assistant #{name} pour=operations\n\n"
    end
    return existe
  end

  # True s'il existe un fichier vocal séparé
  def voice_capture_exists?(required=false)
    existe = File.exists?(vocal_capture_path)
    if !existe && required
      error "Le fichier voix est requis. Pour le produire de façon assistée, utiliser :\n\n\tvite-faits assistant #{name} pour=voix\n\n"
    end
    return existe
  end

  # ---------------------------------------------------------------------
  #   Méthodes pour se rendre sur les lieux
  # ---------------------------------------------------------------------
  def chaine_youtube
    `open -a Safari "#{url_chaine}"`
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
      notice "--> CREATE FOLDER #{pth} 👍"
    end
  end
  # Détruit un fichier s'il existe
  def unlink_if_exist liste
    liste.each do |pth|
      if File.exists?(pth)
        File.unlink(pth)
        notice "---> Destruction de #{pth}"
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
    Dir["#{chantier_folder_path}/*.mov"].each do |pth|
      fname = File.basename(pth)
      if fname === default_source_fname
        return default_source_fname
      elsif fname.downcase != 'titre.mov'
        # On va renommer ce fichier pour qu'il porte le bon nom
        FileUtils.move(pth,default_source_path)
        return default_source_fname
      end
    end
    return nil # non trouvé
  end

  def src_name; @src_name end

  def default_source_fname
    @default_source_fname ||= "#{name}.mov"
  end
  def default_source_path
    @default_source_path ||= pathof(default_source_fname)
  end

  # Chemin d'accès au fichier contenant peut-être les opérations
  # à dire tout haut pour créer plus facilement le programme
  def operations_path
    @operations_path ||= File.join(operations_folder,'operations.yaml')
  end

  def mp4_path
    @mp4_path ||= pathof("#{name}.mp4")
  end
  def ts_path
    @ts_path ||= pathof("#{name}.ts")
  end
  def completed_path
    @completed_path ||= File.join(exports_folder, "#{name}_completed.mp4")
  end
  def scriv_file_path
    @scriv_file_path ||= pathof("#{name}.scriv")
  end
  def screenflow_path
    @screenflow_path ||= pathof("#{name}.screenflow")
  end
  def premiere_path
    @premiere_path ||= pathof("#{name}.prproj")
  end
  # Éléments pour le titre
  def titre_path
    @titre_path ||= File.join(titre_folder, "Titre.scriv")
  end
  def titre_mov
    @titre_mov ||= begin
      default_path = File.join(titre_folder, "Titre.mov")
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
  def titre_mp4
    @titre_mp4 ||= File.join(titre_folder, "Titre.mp4")
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
    @vocal_capture_path ||= pathof('voice.mp4')
  end
  # Le fichiers pour l'assemblage
  # aac car assemblable
  def voice_aac
    @voice_aac ||= pathof('voice.aac')
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

  # Retourne le vrai dossier actuel du tutoriel
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

  def decompte phrase, fromValue
    reste = fromValue
    phrase += " " * 20 + "\r"
    while reste > -1
      # Revenir à la 20e colonne de la 4è ligne
      # print "\033[4;24H"
      # print "\033[;24H"
      s = reste > 1 ? 's' : ''
      phrase_finale = phrase % {nombre_secondes: "#{reste} seconde#{s}"}
      print phrase_finale
      # print "Ouverture du forum dans #{reste} seconde#{s}              \r"
      sleep 1
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
    #       error e.message if e.message
    #     end
    def yesOrStop(question)
      unless yesNo(question)
        raise NotAnError.new
      end
    end

    def machine_a_ecrire_path
      # @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aiff')
      # @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.mp3')
      @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aac')
    end
  end #/ << self
end
