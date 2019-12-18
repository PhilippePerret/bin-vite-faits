# encoding: UTF-8
def vitefait
  @vitefait ||= ViteFait.new(COMMAND.folder)
end

class ViteFait

  class << self

    def require_module module_name
      require File.join(FOLDER_MODULES,module_name)
    end

    def open_help
      if COMMAND.options[:edit] || !File.exists?(VITEFAIT_MANUAL_PATH)
        `open -a Typora "#{VITEFAIT_HELP_PATH}"`
      else
        `open "#{VITEFAIT_MANUAL_PATH}"`
      end
    end

    # Ouvrir quelque chose (dans le finder)
    def open folder
      require_module('open')
      exec_open(folder)
    end

    def open_folder_captures
      if File.exists?(FOLDER_CAPTURES)
        `open -a Finder "#{FOLDER_CAPTURES}"`
      else
        error "Le dossier capture est introuvable (#{FOLDER_CAPTURES})"
        error "Il faut définir son path dans constants.rb (FOLDER_CAPTURES)"
      end
    end

    # Pour lancer l'assistant de création
    def assistant
      require_module('assistant_creation')
      create_with_assistant
    end

  end

  # Le dossier de travail, donc sur l'ordinateur
  # (par opposition au dossier de conservation qui se trouve sur le
  # disque appelé MacOSCatalina)
  attr_accessor :work_folder

  def initialize folder
    self.work_folder = folder
  end

  # ---------------------------------------------------------------------
  #   Les méthodes test et d'état
  # ---------------------------------------------------------------------

  def name_is_required
    if self.defined?
      return false
    else
      error "Il faut définir quel vite-fait utiliser en indiquant le nom de son dossier en second argument."
      return true
    end
  end

  def defined?
    self.work_folder != nil
  end

  def exists?
    File.exists?(work_folder_path)
  end

  def completed?
    File.exists?(completed_path)
  end

  def en_chantier?
    File.exists?(work_folder_path)
  end
  def en_chantier_on_disk?
    File.exists?(work_folder_path_on_disk)
  end
  def completed?
    File.exists?(completed_folder_path)
  end
  def en_attente?
    File.exists?(waiting_folder_path)
  end

  def work_folder_on_disk_exists?
    File.exists?(work_folder_path_on_disk)
  end

  def waiting_folder_exists?
    File.exists?(waiting_folder_path)
  end

  # ---------------------------------------------------------------------
  #   Les actions
  # ---------------------------------------------------------------------

  # Pour créer le vite-fait
  def create
    require_module('create_vite_fait')
    exec_create
  end

  # Pour afficher l'état du tutoriel
  def write_rapport
    require_module('report')
    exec_print_report
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
        open_if_exists(work_folder_path, version2hname(:chantier))
      when 'complete', 'completed'
        open_if_exists(completed_folder_path, version2hname(:complete))
      when 'attente', 'en_attente'
        open_if_exists(waiting_folder_path, version2hname(:waiting))
      when 'chantier_disk', 'en_chantier_on_disk'
        open_if_exists(work_folder_path_on_disk, version2hname(:chantierd))
      end
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

  # Retourne la table des versions existantes
  # Si +key+ est définie, on retourne la liste de ces clés. Par exemple :hname
  # pour obtenir les noms des versions seulement
  def versions(key = nil)
    @versions = []
    en_chantier?          && @versions << :chantier
    completed?            && @versions << :complete
    en_chantier_on_disk?  && @versions << :chantierd
    en_attente?           && @versions << :waiting
    if key.nil?
      @versions
    else
      @versions.collect{|version_id| versionAbs(version_id)[key]}
    end
  end

  # Retourne les informations absolues de la version d'identifiant
  # version_id (qui peut être :chantier, :complete, :waiting ou chantierd)
  def versionAbs version_id
    DATA_VERSION[version_id]
  end
  def version2hname version
    versionAbs(version)[:hname]
  end

  # Un tutoriel peut être placé à 4 endroits différents :
  # Cette méthode retourne le "meilleur" endroit, c'est-à-dire l'endroit où
  # l'on a des chances de rencontrer le dossier le plus à jour
  def current_best_folder
    path, name =
      if en_chantier?
        [work_folder_path, version2hname(:chantier)]
      elsif completed?
        [completed_folder_path, version2hname(:complete)]
      elsif en_chantier_on_disk?
        [work_folder_path_on_disk, version2hname(:chantierd)]
      elsif en_attente?
        [waiting_folder_path, version2hname(:waiting)]
      end
    {path:path, hname:name}
  end

  # Assemble la vidéo complète
  # cf. le module 'assemblage.rb'
  def assemble nomessage = false
    require_module('assemblage')
    exec_assemble(nomessage)
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
    FileUtils.copy_entry(work_folder_path, completed_folder_path)
    notice "---> création du dossier '#{completed_folder_path}'"
    FileUtils.rm_rf(work_folder_path)
    notice "---> Destruction de '#{work_folder_path}'"
    notice "\n=== 👍  Achèvement terminé du tutoriel vite-fait « #{name} »"
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
  def annonce
    require_module('annonces')
    exec_annonce
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
    require_module('annonce_forum_scrivener')
    exec_annonce_forum_scrivener
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
    if File.exists?(path)
      notice "    - fichier #{name}".ljust(26) + ' : oui'
    else
      error "    - fichier #{name}".ljust(26) + ' : non'
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
    @titre ||= informations.data[:titre][:value]
  end
  def titre_en
    @titre_en ||= informations.data[:titre_en][:value]
  end
  def youtube_id
    @youtube_id ||= informations.data[:youtube_id][:value]
  end
  def description
    @description ||= informations.data[:description][:value]
  end



  # ---------------------------------------------------------------------
  #   Tous les paths
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
    Dir["#{work_folder_path}/*.mov"].each do |pth|
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

  # ---------------------------------------------------------------------
  #   Paths
  # ---------------------------------------------------------------------

  def src_name; @src_name end

  def default_source_fname
    @default_source_fname ||= "#{name}.mov"
  end
  def default_source_path
    @default_source_path ||= pathof(default_source_fname)
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
  def pathof relpath
    File.join(work_folder_path,relpath)
  end

  # Chemin d'accès au dossier de travail (sur l'ordinateur)
  def work_folder_path
    @work_folder_path ||= File.join(VITEFAIT_WORK_MAIN_FOLDER,name)
  end


  # Chemin d'accès au dossier sur le disque
  def completed_folder_path
    @completed_folder_path ||= File.join(VITEFAIT_FOLDER_COMPLETED_ON_DISK,name)
  end

  # Chemin d'accès au dossier de travail sur le disque
  def work_folder_path_on_disk
    @work_folder_path_on_disk ||= File.join(VITEFAIT_FOLDER_WORKING_ON_DISK,name)
  end

  # Chemin d'accès au dossier en attente (sur le disque)
  def waiting_folder_path
    @waiting_folder_path ||= File.join(VITEFAIT_FOLDER_PROJECT_ON_DISK,name)
  end

  class << self
    def machine_a_ecrire_path
      # @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aiff')
      # @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.mp3')
      @machine_a_ecrire_path ||= File.join(VITEFAIT_MATERIEL_FOLDER,'machine-a-ecrire.aac')
    end
  end #/ << self
end
