# encoding: UTF-8

class ViteFait

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

  def goto_manual(anchor); self.class.goto_manual(anchor) end
  alias :goto_manuel :goto_manual

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

  # La méthode retourne false si le nom est bien défini
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

    if self.defined? && exists? && valid?
      return true
    elsif self.defined? && exists? && !valid?
      return error "Le tutoriel #{name} n'est pas valide…"
    elsif self.defined?
      candidat = self.class.get_nearer_from_name(name)
      if candidat.nil?
        return error "Je n'ai trouvé aucun tutoriel de ce nom ou proche de ce nom. Je dois renoncer.\n\n"
      end
      if candidat[:similarity] > -3
        yesNo("Je n'ai pas trouvé ce tutoriel ('#{name}')…\nS'agit-il du tutoriel '#{candidat[:name]}' (indice de similarité de #{candidat[:similarity]}) ? (si c'est un nouveau, tape 'n')") || return
        instance_variables.each do |prop|
          instance_variable_set("#{prop}", nil)
        end
        force_tutoriel(candidat[:name])
        return true
      else
        return error "Je n'ai trouvé aucun tutoriel de le nom est ou ressemble à '#{name}'.\n\n"
      end
    else
      error "Un tutoriel existant et valide est requis pour cette opération.\nJe dois m'arrêter là."
    end
    return false
  end

  def force_tutoriel name
    name.nil? && return
    COMMAND.folder = self.work_folder = @name = name
    @vitefait = nil
    check_tutoriel
    return name
  end


  # ---------------------------------------------------------------------
  #   Les actions
  # ---------------------------------------------------------------------


  # ---
  #   Méthodes de création
  # ---

  # Pour créer le vite-fait
  def create(nomessage = true)
    if COMMAND.options[:help]
      goto_manual('commandescreation')
    else
      require_module('tutoriel/create')
      exec_create(nomessage)
    end
  end

  def check
    require_module('tutoriel/check')
    exec_check
  end

  # Lorsque des modifications ont été faites, ou une nouvelle étape
  # créée.
  def save_last_logic_step
    require_module('tutoriel/conception')
    conception.save_last_logic_step
  end
  # ---
  #   Pour les opérations
  # ---

  # Méthode appelée lorsque l'on utilise la commande 'operations' seules,
  # avec des options par exemple
  def commande_operations
    if COMMAND.options[:help]
      return ViteFait.goto_manual('lesoperations')
    else
      is_required || return
      if COMMAND.options[:edit]
        open_something('operations')
      elsif COMMAND.options[:record]
        record_operations
      else
        # On veut simplement voir les opérations
        open_something('operations')
      end
    end
  end

  # Pour créer le fichier des opérations de façon assistées
  def create_file_operations
    return goto_manual('lesoperations') if COMMAND.options[:help]
    require_module('operations/operations')
    assistant_creation_file
  end

  # Pour récupérer les opérations définies
  # Return un Hash vide si le fichier n'existe pas.
  # Note : il vaut mieux utiliser la méthode-propriété 'operations' qui
  # retourne une liste des instances d'Operation(s)
  def get_operations
    return goto_manual('lesoperations') if COMMAND.options[:help]
    operations_defined? || (return {})
    # Dans un premier temps, on s'assure que le fichier
    begin
      conformize_operations_file
    rescue Exception => e
      raise e
    end
    begin
      YAML.load_file(operations_path).to_sym
    rescue Exception => e
      error "Une erreur est survenue au cours de la lecture du fichier YAML. Je dois renoncer"
      raise e
    end
  end

  def operations
    @operations ||= get_operations.collect{|dope|Operation.new(dope)}
  end

  # Pour lancer la lecture des opérations définies
  def record_operations
    return goto_manual('lesoperations') if COMMAND.options[:help]
    require_module('operations/record')
    exec
  rescue NotAnError => e
    e.puts_error_if_message
    error "OK, on abandonne.\n\n"
  end

  # Méthode qui s'assure que le fichier YAML est correct. Pas seulement
  # "parsable" mais aussi correct, c'est-à-dire, par exemple, qu'il ne
  # contient pas de menu inscrits comme "Fichier > Ouvrir" car le signe
  # supérieur signifierait un here-doc qui supprimerait donc toute ce
  # qui le suit, pour ne prendre que la ligne suivante.
  def conformize_operations_file
    code = File.read(operations_path).force_encoding('utf-8')
    hasBeenModified = false
    if code.match(/>(?! ?\r?\n)/)
      error <<-EOE
J'ai trouvé un caractère '>' dans le code des opérations qui n'était
pas utilisé comme marqueur de HEREDOC. J'ai corrigé le code mais il
faut s'abstenir de cette utilisation. Si c'est pour un menu, utiliser
plutôt, comme délimiteur, le caractère '››' qui se fait avec ALT-MAJ-w
(Édition››Recherche››Rechercher››Remplacer).
      EOE
      code.gsub!(/ ?>(?! ?\r?\n)/){
        # ",#{$1}"
        ","
      }
      hasBeenModified = true
    end
    if hasBeenModified
      File.open(operations_path,'wb'){|f| f.write(code)}
    end
  end

  def update_from
    require_module('tutoriel/update')
    update
  end
  # Retourne true si le fichier capture des
  # opérations existe, false dans le cas contraire.
  # Si +required+ est true, produit une erreur en
  # cas d'absence
  def operations_recorded?(required = false, nomessage = true)
    existe = record_operations_path(noalert = true) && File.exists?(record_operations_path)
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
  #   operations_defined?(true) || return
  def operations_defined?(required = false, nomessage = true)
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
  #   Méthodes de tâches
  # ---
  def commande_taches
    require_module('tools/taches')
    exec_commande_taches
  end

  # ---
  #   Méthodes pour les notifications
  # ---
  def commande_notifications
    require_module('tools/notifications')
    exec_commande_notifications
  end

  # ---
  #   Méthodes de rapport
  # ---

  # Pour afficher l'état du tutoriel
  def write_rapport
    return goto_manual('lerapport') if COMMAND.options[:help]
    require_module('tutoriel/report')
    exec_print_report
  end

  # ---
  #   Méthodes d'ouverture
  # ---

  # Méthode générale utiliser pour ouvrir n'importe quel élément
  # du vite-fait
  def open_something what = nil, edition = nil
    require_module('every/open')
    exec_open(what, edition)
  end

  # Méthode générique pour enregistrer les éléments.
  # +what+ peut être 'operations'/'o', 'titre'/'t', 'voice'/'v'
  def record_something what
    what = SHORT_SUJET_TO_REAL_SUJET[what] || what
    send("record_#{what}".to_sym)
  end

  # Méthode générique pour cropper un enregistrement
  def crop
    require_module('videos/crop')
    exec_crop
  rescue NotAnError => e
    e.puts_error_if_message
  end

  def assemble_something what
    what = SHORT_SUJET_TO_REAL_SUJET[what] || what
    send("assemble_#{what}".to_sym)
  end

  def voir_something what
    require_module('videos/voir')
    exec_voir(what)
  end


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

  def scrivener_project
    @scrivener_project ||= begin
      require_module('scrivener_project')
      ScrivenerProject.new(self)
    end
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

  def record_titre
    require_module('titre/assistant')
    exec
    notice "Pour finaliser ce titre, joue :\n\n\tvite-fait assemble_titre[ #{name}]"
  rescue NotAnError => e
    e.puts_error_if_message
    error "J'abandonne…"
  end

  def destroy
    require_module('tutoriel/destroy')
    exec_destroy
  end

  # ---
  #   Méthodes de conversion
  # ---

  # Pour transformer le fichier capture en vidéo mp4
  def capture_to_mp4
    operations_recorded?(required=true) || return
    require_module('operations/capture_to_mp4')
    exec_capture_to_mp4
  end

  # Méthode de transformation du titre en fichier mp4
  def assemble_titre
    require_module('titre/assemble')
    exec_assemble_titre
  end


  # Assemble la vidéo complète
  # cf. le module 'assemblage.rb'
  def assemble nomessage = false
    require_module('tutoriel/assemblage')
    exec_assemble(nomessage)
  rescue NotAnError => e
    e.puts_error_if_message
  end

  # Assemble la vidéo de la capture et la voix
  def assemble_capture nomessage = true
    require_module('operations/assemblage_capture')
    exec_assemble_capture(nomessage)
  end

  # Ne conserve qu'un seul dossier
  # C'est le paramètre :lieu qui définit le lieu
  def keep_only_folder
    require_module('folder/keep_only')
    exec_keep_only_folder
  end

  # Méthode appelée pour déplacer le tutoriel
  def move
    require_module('folder/move')
    exec_move
  end

  # ---
  #   Autres méthodes
  # ---

  # Pour assister la fabrication finale de la voix du tutoriel
  # en affichant le texte défini dans le fichier des opérations.
  def record_voice
    require_module('voice/record')
    exec
  rescue NotAnError => e
    e.puts_error_if_message
    error "Nous abandonnons."
  end

  def edit_voice_file
    require_module('voice/edit_voice_file')
    edition_fichier_voix
  rescue NotAnError => e
    e.puts_error_if_message
    error "Abandon…"
  end

  # True s'il existe un fichier vocal séparé
  def voice_capture_exists?(required=false,nomessage=true)
    existe = File.exists?(record_voice_path)
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
      require_module('informations/informations')
      Informations.new(self)
    end
  end
  alias :infos :informations

  # Méthode appelée pour uploader la vidéo sur YouTube
  # En fait, ça ouvre l'interface pour le faire + le dossier contenant
  # la vidéo à uploader
  def upload
    require_module('tutoriel/upload')
    exec_upload
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
  # Si aucun dossier n'est défini dans la ligne de commande, on essaie
  # de prendre le dernier tutoriel utilisé
  def defined?
    self.work_folder ||= force_tutoriel(ViteFait.current_tutoriel)
    self.work_folder && begin
      ViteFait.current_tutoriel= self.work_folder
      @vitefait = nil
    end
    self.work_folder != nil
  end

  def exists?
    self.defined? || (return false)
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
  alias :en_chantier? :folder_en_chantier?

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
    existe = File.exists?(record_operations_mp4)
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

  def video_on_youtube?
    require_module('videos/youtube')
    is_video_on_youtube?
  end

  # ---------------------------------------------------------------------
  #   Méthodes pour se rendre sur les lieux
  # ---------------------------------------------------------------------

  def video_url
    @video_url ||= begin
      if youtube_id.nil?
        error "Ce tutoriel ne semble pas encore déposé sur YouTube."
        nil
      else
        "https://www.youtube.com/watch?v=#{youtube_id}"
      end
    end
  end

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
    require_module('tools/annonces')
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
      IO.remove_with_care(pth,"fichier #{relative_pathof(pth)}",true)
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
  def record_operations_path(no_alert = false)
    @record_operations_path ||= begin
      if File.exists?(default_record_operations_path)
        @record_operations_name = default_record_operations_fname
        default_record_operations_path
      else
        record_operations_name = COMMAND.params[:name] || get_first_mov_file()
        if record_operations_name.nil?
          unless no_alert
            error "🖐  Je ne trouve aucun fichier .mov à traiter.\nSi le fichier est dans une autre extension, préciser explicement son nom avec :\n\t`vite-faits capture_to_mp4 #{name} name=nom_du_fichier.ext`."
          end
          nil
        else
          @record_operations_name = File.basename(record_operations_name)
          pathof(record_operations_name)
        end
      end
    end
  end
  alias :record_operations_mov :record_operations_path

  def get_first_mov_file
    Dir["#{operations_folder}/*.mov"].each do |pth|
      fname = File.basename(pth)
      if fname === default_record_operations_fname
        return default_record_operations_fname
      elsif fname.downcase != 'capture.mov'
        # On va renommer ce fichier pour qu'il porte le bon nom
        FileUtils.move(pth, default_record_operations_path)
        return default_record_operations_fname
      end
    end
    return nil # non trouvé
  end

  def record_operations_name; @record_operations_name end

  def default_record_operations_fname
    @default_record_operations_fname ||= "capture.mov"
  end
  def default_record_operations_path
    @default_record_operations_path ||= File.join(operations_folder, default_record_operations_fname)
  end

  # Chemin d'accès au fichier contenant peut-être les opérations
  # à dire tout haut pour créer plus facilement le programme
  def operations_path
    @operations_path ||= File.join(operations_folder,'operations.yaml')
  end

  def record_operations_mp4
    @record_operations_mp4 ||= File.join(operations_folder, "capture.mp4")
  end
  def record_operations_cropped_mp4
    @record_operations_cropped_mp4 ||= File.join(operations_folder, "capture-cropped.mp4")
  end
  def record_operations_ts
    @record_operations_ts ||= File.join(operations_folder, "capture.ts")
  end

  # Fichier vidéo final
  # -------------------
  def final_tutoriel_mp4
    @final_tutoriel_mp4 ||= File.join(exports_folder, "#{name}_completed.mp4")
  end
  def final_tutoriel_exists?(required=false)
    existe = File.exists?(final_tutoriel_mp4)
    if !existe && required
      error "Le fichier tutoriel final (*) est requis…\n(*) #{final_tutoriel_mp4}"
      return false
    else
      return true
    end
  end

  # Projet scrivener
  # ----------------
  def scriv_file_path
    @scriv_file_path ||= pathof(scriv_file_name)
  end
  def scriv_file_name
    @scriv_file_name ||= "#{name}-prepared.scriv"
  end
  def screenflow_path
    @screenflow_path ||= pathof("Montage.screenflow")
  end
  def premiere_path
    @premiere_path ||= pathof("Montage.prproj")
  end

  def titre_recorded?(required = false)
    existe = titre_mov && File.exists?(titre_mov)
    if !existe && required
      error "L'enregistrement du titre devrait exister. Pour le produire, jouer :\n\n\tvite-faits assistant #{name} pour=titre\n\n"
    end
    return existe
  end

  # Retourne true si le titre.mp4 a été produit
  def titre_finalized?
    titre_recorded? && File.exists?(record_titre_mp4)
  end

  # Éléments pour le titre
  def titre_path
    @titre_path ||= File.join(titre_folder, "Titre.scriv")
  end
  def titre_mov
    @titre_mov ||= begin
      default_path = record_titre_mov
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
  def record_titre_mov
    @record_titre_mov ||= File.join(titre_folder, "Titre.mov")
  end
  def record_titre_mp4
    @record_titre_mp4 ||= File.join(titre_folder, "Titre.mp4")
  end
  def titre_prov_mp4
    @titre_prov_mp4 ||= File.join(titre_folder, "Titre-prov.mp4")
  end
  def record_titre_ts
    @record_titre_ts ||= File.join(titre_folder, "Titre.ts")
  end
  # Chemin d'accès au dossier titre
  def titre_folder
    @titre_folder ||= pathof("Titre")
  end

  # ---
  #   Dossiers
  # ---

  def operations_folder
    @operations_folder ||= pathof('Operations')
  end

  def assets_folder
    @assets_folder ||= pathof('Assets')
  end
  # Le fichiers final de la voix, si elle est utilisée
  # mp4 car éditable par Audacity
  def record_voice_path
    @record_voice_path ||= File.join(voice_folder,'voice.mp4')
  end
  alias :record_voice_mp4 :record_voice_path
  def record_voice_aiff
    @record_voice_aiff ||= File.join(voice_folder,'voice.aiff')
  end
  # Le fichiers pour l'assemblage
  # aac car assemblable
  def record_voice_aac
    @record_voice_aac ||= File.join(voice_folder,'voice.aac')
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

  # Introduction propre ?
  def has_own_intro?
    File.exists?(own_intro_mp4) || File.exists?(own_intro_ts)
  end
  def own_intro_mp4
    @own_intro_mp4 ||= pathof('Assets/intro.mp4')
  end
  def own_intro_ts
    @own_intro_ts ||= pathof('Assets/intro.ts')
  end

  # Final propre ?
  def has_own_final?
    File.exists?(own_final_mp4) || File.exists?(own_final_ts)
  end
  def own_final_mp4
    @own_final_mp4 ||= pathof('Assets/final.mp4')
  end
  def own_final_ts
    @own_final_ts ||= pathof('Assets/final.ts')
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

  # Pour faire dire un texte
  def dire text
    `say -v Audrey "#{text}" `
  end

end
