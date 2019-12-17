# encoding: UTF-8
def vitefait
  @vitefait ||= ViteFait.new(COMMAND.folder)
end

class ViteFait

  class << self

    def open_help
      `open -a Typora "#{VITEFAIT_HELP_PATH}"`
    end

    # Ouvrir quelque chose (dans le finder)
    def open folder
      if folder.nil?
        error "Il faut indiquer ce qu'il faut ouvrir…"
      else
        case folder
        when 'disk'
          `open -a Finder "#{VITEFAIT_FOLDER_ON_DISK}"`
        when 'laptop'
          `open -a Finder "#{VITEFAIT_FOLDER_ON_LAPTOP}"`
        else
          error "Je ne sais pas couvrir '#{folder}'."
        end
      end
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

  def completed_folder_exists?
    File.exists?(completed_folder_path)
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
    print_rapport_existence
    if completed?
      notice "Ce tutoriel pourrait être déplacé vers le disque (`vite-faits complete #{name}`)."
    end
  end

  # Pour transformer le fichier capture en vidéo mp4
  def capture_to_mp4
    require_module('traite_capture_operations')
    exec_capture_to_mp4
  end

  def open_vignette
    if File.exists?(vignette_gimp)
      `open -a Gimp "#{vignette_gimp}"`
      notice "Modifie le titre puis export en jpg sous le nom 'Vignette.jpg'"
    else
      error "Le fichier vignette est introuvable\n#{vignette_gimp}"
    end
  end

  def open_titre
    if File.exists?(titre_path)
      `open -a Scrivener "#{titre_path}"`
      notice "Règle la largeur de la fenêtre pour avoir un beau titre\nEnregistre le titre en capturant son écriture,\nRécupère-le dans le dossier des captures,\nDéplace-le dans le dossier 'Titre' du dossier du tutoriel\nEt prépare-le si nécessaire avec la commande `vite-faits traite_titre #{name}.`"
    else
      error "Le fichier Titre.scriv est introuvable…\n#{titre_path}"
    end
  end

  # Méthode de transformation du titre en fichier mp4
  def titre_to_mp4
    unless File.exists?(titre_mov)
      raise "🖐  Le fichier `Titre.mov` est introuvable. Il faut capturer le titre en se servant du fichier Titre.scriv"
    end
    unless File.exists?(self.class.machine_a_ecrire_path)
      raise "🖐  Impossible de trouver le son de machine à écrire (#{self.class.machine_a_ecrire_path}). Or j'en ai besoin pour créer le titre."
    end

    unlink_if_exist([titre_mp4, titre_ts])

    # ffmpeg -i video.avi -i audio.mp3 -codec copy -shortest output.avi
    # cmd = "ffmpeg -i \"#{titre_mov}\" -i \"#{self.class.machine_a_ecrire_path}\" -codec copy -shortest \"#{titre_mp4}\""
    # cmd = "ffmpeg -i \"#{titre_mov}\" -i \"#{self.class.machine_a_ecrire_path}\" -c:v libx264 -c:a libvorbis -shortest \"#{titre_mp4}\""
    cmd = "ffmpeg -i \"#{titre_mov}\" -i \"#{self.class.machine_a_ecrire_path}\" -codec copy -shortest \"#{titre_mp4}\""
    COMMAND.options[:verbose] && cmd << ' 2> /dev/null'
    puts "\n\n---- Commande jouée : #{cmd}"
    res = `#{cmd}`
    if File.exists?(titre_mp4)
      notice "= 👍  Fichier titre mp4 fabriqué avec succès."
    else
      error "Le fichier titre mp4 n'a pas pu être fabriqué…"
    end

  rescue Exception => e
    error "#{e.message}.\nJe ne peux pas faire le fichier .mp4 du titre"
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

  # Assemble la vidéo complète
  # cf. le module 'assemblage.rb'
  def assemble
    require_module('assemblage')
    exec_assemble
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


  # Écrit un rapport pour savoir où l'on en est de ce dossier vite-fait
  def print_rapport_existence
    if vitefait.defined?
      if vitefait.exists?
        notice "Dossier travail vite-fait : '#{vitefait.work_folder}'."
        line_exists_file(screenflow_path, 'ScreenFlow')
        line_exists_file(scriv_file_path, 'Scrivener')
        line_exists_file(src_path, 'source')
        line_exists_file(mp4_path, 'capture.mp4')
        line_exists_file(ts_path, 'capture.ts')
        line_exists_file(completed_path, 'VIDÉO FINALE')
      else
        if COMMAND.options[:check]
          error "Le dossier travail vite-fait '#{vitefait.work_folder_path}' n'existe pas."
          if vitefait.completed_folder_exists?
            notice "Mais il existe en tant que dossier fini sur le disque."
          elsif vitefait.work_folder_on_disk_exists?
            notice "Mais il existe en tant que dossier en chantier sur le disque. Pour le mettre en dossier de travail sur l'ordinateur, utiliser la commande `./bin/vitefait.rb work #{vitefait.name}`"
          elsif vitefait.waiting_folder_exists?
            notice "Mais il existe en tant que dossier en projet sur le disque. Pour le mettre en dossier de travail sur l'ordinateur, utiliser la commande `./bin/vitefait.rb work #{vitefait.name}`"
          end
        end
      end
    end
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
    require File.join(FOLDER_MODULES,module_name)
  end

  # ---------------------------------------------------------------------
  #   Les propriétés volatiles
  # ---------------------------------------------------------------------

  def name
    @name ||= work_folder
  end

  # ---------------------------------------------------------------------
  #   Tous les paths
  # ---------------------------------------------------------------------

  def src_path
    @src_path ||= begin
      src_name = COMMAND.params[:name] || get_first_mov_file()
      if src_name.nil?
        error "🖐  Je ne trouve aucun fichier .mov à traiter.\nSi le fichier est dans une autre extension, préciser explicement son nom avec :\n\t`vite-faits capture_to_mp4 #{name} name=nom_du_fichier.ext`."
      else
        @src_name = File.basename(src_name)
        File.join(work_folder_path,src_name)
      end
    end
  end
  def get_first_mov_file
    Dir["#{work_folder_path}/*.mov"].each do |pth|
      if File.basename(pth).downcase != 'titre.mov'
        return File.basename(pth)
      end
    end
  end
  def src_name; @src_name end
  def mp4_path
    @mp4_path ||= File.join(work_folder_path, "#{name}.mp4")
  end
  def ts_path
    @ts_path ||= File.join(work_folder_path, "#{name}.ts")
  end
  def completed_path
    @completed_path ||= File.join(exports_folder, "#{name}_completed.mp4")
  end
  def scriv_file_path
    @scriv_file_path ||= File.join(work_folder_path, "#{name}.scriv")
  end
  def screenflow_path
    @screenflow_path ||= File.join(work_folder_path, "#{name}.screenflow")
  end
  def premiere_path
    @premiere_path ||= File.join(work_folder_path, "#{name}.prproj")
  end

  # Éléments pour le titre
  def titre_path
    @titre_path ||= File.join(titre_folder, "Titre.scriv")
  end
  def titre_mov
    @titre_mov ||= File.join(titre_folder, "Titre.mov")
  end
  def titre_mp4
    @titre_mp4 ||= File.join(titre_folder, "Titre.mp4")
  end
  def titre_ts
    @titre_ts ||= File.join(titre_folder, "Titre.ts")
  end
  # Chemin d'accès au dossier titre
  def titre_folder
    @titre_folder ||= File.join(work_folder_path, "Titre")
  end

  def vignette_gimp
    @vignette_gimp ||= File.join(vignette_folder, 'Vignette.xcf')
  end
  # Éléments pour la vignette
  def vignette_folder
    @vignette_folder ||= File.join(work_folder_path, "Vignette")
  end

  # Chemin d'accès au dossier des exports
  def exports_folder
    @exports_folder ||= File.join(work_folder_path, "Exports")
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
