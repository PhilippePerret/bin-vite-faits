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
    if exists? && !COMMAND.options[:force]
      error "Ce projet existe déjà, je ne peux pas le créer."
    else

      if exists? && COMMAND.options[:force]
        FileUtils.rm_rf(work_folder_path)
      end

      # Création du dossier
      Dir.mkdir(work_folder_path)
      notice "--> Dossier #{work_folder_path}"

      # Copie du fichier scrivener
      src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Vite-Faits.scriv')
      dst = File.join(work_folder_path, "#{name}.scriv")
      FileUtils.copy_entry(src, dst)
      src_x = File.join(work_folder_path,"#{name}.scriv",'Vite-Faits.scrivx')
      dst_x = File.join(work_folder_path, "#{name}.scriv", "#{name}.scrivx")
      FileUtils.move(src_x, dst_x)
      notice "--> Scrivener : #{dst}"

      # Copie du gabarit Screenflow
      src = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel','gabarit.screenflow')
      dst = File.join(work_folder_path, "#{name}.screenflow")
      FileUtils.copy_entry(src, dst)
      notice "---> Screenflow : #{dst}"

      notice "\n\nNouveau vite-fait créé avec succès"
      `open -a Finder "#{work_folder_path}"`
    end
  end

  # Pour afficher l'état du tutoriel
  def write_rapport
    print_rapport_existence
    if completed?
      notice "Ce tutoriel pourrait être déplacé vers le disque (`vite-faits complete #{name}`)."
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
    notice "\n=== Achèvement terminé du tutoriel vite-fait « #{name} »"
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

  def line_exists_file path, name
    if File.exists?(path)
      notice "    - fichier #{name}".ljust(26) + ' : oui'
    else
      error "    - fichier #{name}".ljust(26) + ' : non'
    end
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
    @src_path ||= File.join(work_folder_path, "#{name}.mov")
  end
  def mp4_path
    @mp4_path ||= File.join(work_folder_path, "#{name}.mp4")
  end
  def ts_path
    @ts_path ||= File.join(work_folder_path, "#{name}.ts")
  end
  def completed_path
    @completed_path ||= File.join(work_folder_path, "#{name}_completed.mp4")
  end
  def scriv_file_path
    @scriv_file_path ||= File.join(work_folder_path, "#{name}.scriv")
  end
  def screenflow_path
    @screenflow_path ||= File.join(work_folder_path, "#{name}.screenflow")
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
end
