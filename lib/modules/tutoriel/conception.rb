# encoding: UTF-8
=begin
  class ViteFait::Conception
  --------------------------
  Module pour l'aide à la conception d'un tutoriel
  Tout ce qui concerne la conception au sens large.

  Instance `vitefait.conception`

=end

def writeline lines, nombre_espaces
  lines = lines.split(/\r?\n/)
  tab = " " * nombre_espaces
  puts tab + lines.join("\n#{tab}")
end


class ViteFait
  def conception
    @conception ||= Conception.new(self)
  end

  # ---------------------------------------------------------------------
  #   Classe ViteFait::Conception
  #   Gestion des données de conception
  # ---------------------------------------------------------------------
  class Conception
    attr_reader :tuto
    def initialize tuto
      @tuto = tuto
    end

    # = main =
    # Méthode principale appelée par la commande 'conception'
    def display
      case COMMAND.params[:step]
      when 'next', 'prochaine'
        display_next_logic_step
      when 'current', 'courante', 'derniere', 'last'
        display_last_logic_step
      when 'each', 'chacune'
        display_step_by_step
      else
        if (COMMAND.params[:format]||'').downcase == 'html'
          error "La sortie en format HTML n'est pas encore implémentée."
        else
          display_all
        end
      end
    end

    # Affichage de toutes les étapes
    def display_all
      steps.each do |step|
        step.display
      end
    end

    def display_step_by_step
      steps.each do |step|
        clear
        step.display
        yesOrStop("\n\nÉtape suivante ?")
      end
    rescue NotAnError => e
      e.puts_error_if_message
    end

    # Affiche la dernière étape accomplie, déduite en fonction
    # des éléments qu'on trouve dans le dossier et les informations
    def display_last_logic_step
      clear
      notice "D'après les éléments présents, j'ai pu déterminer que la dernière étape accomplie était :"
      last_logic_step.display
    end

    # Affiche la prochaine étape à accomplir.
    def display_next_logic_step
      clear
      next_step = steps[last_logic_step.index]
      if next_step.nil?
        notice "Vous avez atteint la dernière étape."
      else
        next_step.display
      end
    end

    # Retourne la liste des étapes de conception sous une forme
    # d'instance {ViteFait::Conception::Step}.
    def steps
      @steps ||= begin
        index = 0
        YAML.load(YAML_DATA_CONCEPTION % {folder: File.basename(File.dirname(tuto.current_folder)), name: tuto.name}).to_sym.collect do |dstep|
          dstep.merge!(index: (index += 1))
          Step.new(tuto, dstep)
        end
      end
    end

    # Méthode qui enregistre la dernière étape logique de
    # conception, pour savoir où en est le tutoriel en
    # question.
    # A été inauguré pour voir où en était chaque tutoriel
    #
    # Pour l'appeler : `self.conception.save_last_logic_step`
    #
    # +return+ {Integer}  L'index de l'étape courante (certaines
    #                     méthodes en ont vraiment besoin)
    def save_last_logic_step
      tuto.informations.set({logic_step: last_logic_step.index})
      return last_logic_step.index
    end

    # Retourne l'instance ViteFait::Conception::Step de la
    # dernière étape logique.
    def last_logic_step
      @last_logic_step ||= search_for_last_logic_step
    end

    def search_for_last_logic_step
      steps.each do |step|
        step.valid? || begin
          return steps[step.index - 2]
        end
      end
    end #search_for_last_logic_step


    # ---------------------------------------------------------------------
    #   CLASSE ViteFait::Conception::Step
    #   Pour une étape de conception
    # ---------------------------------------------------------------------
    class Step
      attr_reader :tuto
      attr_reader :data
      attr_reader :errors_validity
      def initialize tuto, data
        @tuto = tuto
        @data = data
      end

      # Retourne true si l'étape de conception est valide
      # +Params+::
      #   +deep+::[Boolean] Si true, on fait une recherche sur tous les éléments
      #                     requis. Sinon, au premier élément manquant, on
      #                     s'arrête.
      def valid?(deep = false)
        errors = []
        self.produit.each do |pth|
          path  = File.join(VITEFAIT_FOLDER_ON_LAPTOP, pth)
          pathd = File.join(VITEFAIT_FOLDER_ON_DISK, pth)
          # puts "2 chemins testés :\n#{path}\n#{pathd}"
          (File.exists?(path) || File.exists?(pathd)) && next
          # puts "Impossible de trouver le path #{path}"
          if deep
            errors << "Dossier/fichier introuvable : #{pth}"
          else
            return false
          end
        end
        self.informations.each do |kinfo|
          tuto.informations[kinfo.to_sym] === true && next
          if deep
            errors << "Information à false : #{kinfo}"
          else
            return false
          end
        end
        @errors_validity = errors
        return errors.empty?
      end #/valid?

      MARGE_ESPACES = 5
      # Affichage d'une étape
      def display
        write_yellow "\n\n#{index.to_s.rjust(3)}. #{hname.upcase}"
        writeline("\n= Description =", MARGE_ESPACES)
        writeline(description, MARGE_ESPACES)
        writeline("\n= Méthodes utiles pour cette étape =",MARGE_ESPACES)
        supports.each do |support|
          support.display
        end
        # Les fichiers qui doivent être produits (existants) poru que
        # l'étape soit validée
        produit && begin
          writeline("\n= L'étape produit =", MARGE_ESPACES)
          produit.each do |prod|
            writeline("  --> #{File.basename(prod)}", MARGE_ESPACES)
          end
        end
        # Les informations qui doivent être true pour que l'étape
        # soit validée
        informations && begin
          writeline("\n= Les informations mises à true =", MARGE_ESPACES)
          informations.each do |info|
            writeline("  --> #{info}", MARGE_ESPACES)
          end
        end
      end

      # Volatile Properties
      def supports
        @supports ||= begin
          support.collect do |dsuppor|
            Support.new(self, dsuppor)
          end
        end
      end

      # Fix Properties
      def id;           @id           ||= data[:id]               end
      def hname;        @hname        ||= data[:hname]            end
      def index;        @index        ||= data[:index]            end
      def letter;       @letter       ||= data[:letter]           end
      def description;  @description  ||= data[:description]      end
      def support;      @support      ||= data[:support]          end
      def produit;      @produit      ||= data[:produit]||[]      end
      def informations; @informations ||= data[:informations]||[] end


      # ---------------------------------------------------------------------
      #   Class ViteFait::Conception::Step::Support
      #   Les lignes de support
      # ---------------------------------------------------------------------
      class Support
        attr_reader :step, :data
        def initialize step, data
          @step = step
          @data = data
        end

        # Affichage de l'aide manuel
        def display
          if command
            write_green "\t#{hname}"
            command && write_cyan("\t  vite-faits #{command}")
          end
          # TODO Quand on pourra sortir une version HTML, on pourra mettre
          # un lien vers le mode d'emploi.
          # manuel && puts("\t  Ancre manuel : ##{manuel}")
        end

        def hname;    @hname    ||= data[:hname]    end
        def command;  @command  ||= data[:command]  end
        def manuel;   @manuel   ||= data[:manuel]   end

      end #/ViteFait::Conception::Step::Support
    end #/ViteFait::Conception::Step
  end #/ViteFait::Conception

end #/ViteFait

YAML_DATA_CONCEPTION = <<-YAML
---
- id: creation_dossier
  letter: D
  hname: Création du dossier
  description: |
      Création du dossier du tutoriel et de tous ses éléments.
  support:
    - hname: Constitution d'un dossier tutoriel
      manuel: structuretutorielfolder
    - hname: Création du dossier tutoriel
      manuel: creationdossiertutoriel
      command: "create %{name}"
  produit:
    - "%{folder}/%{name}"
    - "%{folder}/%{name}/%{name}-prepared.scriv"
    - "%{folder}/%{name}/Exports"
    - "%{folder}/%{name}/Titre"
    - "%{folder}/%{name}/Operations"
    - "%{folder}/%{name}/Vignette"
    - "%{folder}/%{name}/Voix"

- id: define_infos
  letter: I
  hname: Définition des informations générales
  description: |
    Au cours de cette étape on définit les informations générales
    du tutoriel, donc son titre humain, son titre anglais ainsi
    sa description.
  support:
    - hname: Définir les informations générales du tutoriel
      command: infos %{name} titre=\"...\" titre_en=\"...\" description=\"...\"
    - hname: Éditer toutes les informations générales
      command: "infos -e %{name}"
    - hname: Lire les informations générales
      command: "infos %{name}"
  produit:
    - "%{folder}/%{name}/infos.json"

- id: prepared_project_and_operations
  letter: O
  hname: Projet Scrivener préparé et Opérations
  description: |
      Préparation du projet Scrivener qui va servir de base, tout
      en établissant les opérations successives — et les textes à
      dire — du tutoriel.
  support:
    - hname: Ouvrir le projet Scrivener pour le préparer
      manuel: projetscrivenerprepared
      command: "-e open_scrivener %{name}"
    - hname: Initier le fichier des opérations
      command: assistant %{name} pour=operations
      manuel: operationsfile
    - hname: Éditer le fichier opérations pour le modifier
      manuel: operationsfile
      command: -e operations %{name}
    - hname: Essayer le projet préparé
      manuel: projetscrivenerprepared
      command: "open_scrivener %{name}"
    - hname: Lire les opérations pour essayer
      manuel: operationsfile
      command: "lire_operations %{name}"
  produit:
    - "%{folder}/%{name}/%{name}-prepared.scriv"
    - "%{folder}/%{name}/Operations/operations.yaml"

- id: record_titre
  letter: T
  hname: Enregistrement du titre du tutoriel
  description: |
    Cette étape consiste à enregistrer la capture du titre qui
    apparaitra après l'introduction et sera tapé comme sur une
    machine à écrire. On se sert du fichier `Titre/titre.scriv`
    et on capture son écriture.
  support:
    - hname: Capturer le titre
      command: "assistant pour=titre %{name}"
      manuel: recordtitre
  produit:
    - "%{folder}/%{name}/Titre/Titre.mov"

- id: assemblage_titre
  letter: U
  hname: Assemblage du titre
  description: |
    Dans cette étape, on va assembler le titre capturé au cours
    de l'étape précédente avec le son de machine à écrire.
  support:
    - hname: Assembler le titre
      command: "assemble pour=titre %{name}"
      manuel: recordtitre
  produit:
    - "%{folder}/%{name}/Titre/Titre.mp4"

- id: capture_operations
  letter: C
  hname: Capturer les opérations
  description: |
    C'est le plus gros morceau du tutoriel, qui consiste à jouer
    toutes les opérations déterminées en les capturant.
  support:
    - hname: Capturer les opérations
      command: "assistant pour=operations %{name}"
      manuel: captureoperations
  produit:
    - "%{folder}/%{name}/Operations/capture.mov"

- id: recordvoice
  letter: V
  hname: Enregistrement de la voix
  description: |
    Au cours de cette étape, on va procéder à l'enregistrement
    du texte qui doit être dit sur la capture des opérations.
    Cette étape est entièrement assistée pour être d'une simpli-
    cité enfantine.
  support:
    - hname: Capturer la voix avec l'assistant
      command: "assistant pour=voix [%{name}]"
      manuel: recordvoice
  produit:
    - "%{folder}/%{name}/Voix/voice.mp4"

- id: affine_voix
  letter: W
  hname: Affinement de la voix
  description: |
    On va utiliser Audacity ou autre logiciel de traitement de la
    voix pour parachever le fichier voix, notamment en augmentant
    l'intensité et en supprimant le bruit.
  support:
    - hname: Améliorer la qualité du fichier voix
      command: edit_voice %{name}
  produit:
    - "%{folder}/%{name}/Voix/voice.aiff"

- id: assemblagecomplet
  letter: A
  hname: Assemblage du tutoriel complet
  description: |
    C'est cette étape qui va produire le tutoriel complet à uploa-
    der sur YouTube (prochaine étape).
  support:
    - hname: Assembler tous les éléments
      command: "assemble [%{name}]"
  produit:
    - "%{folder}/%{name}/Operations/capture.ts"
    - "%{folder}/%{name}/Titre/Titre.ts"
    - "%{folder}/%{name}/Exports/%{name}_completed.mp4"

- id: production_vignette
  letter: J
  hname: Fabrication de la vignette YouTube
  description: |
    Cette étape permet de produire le fichier JPEG de la vignette
    qui sera utilisé sur YouTube, mais également sur le forum
    Scrivener.
  support:
    - hname: Ouvrir la vignette pour produire l'image
      command: "open_vignette [%{name}]"
      manuel: produirevignette
  produit:
    - "%{folder}/%{name}/Vignette/vignette.jpg"

- id: upload_youtube
  letter: Y
  hname: Upload sur YouTube
  description: |
    Une fois tous les éléments préparés, on peut procéder au télé-
    chargement de la vidéo sur YouTube. L'assistant rejoint la page
    de téléchargement.
    Au besoin, on s'identifie avec le compte Yahoo.
  support:
    - hname: Rejoindre la page de téléchargement
      command: chaine_youtube
      manuel: gotoyoutube
  produit: null
  informations:
    - uploaded

- id: annonces
  letter: S
  hname: Annonce du nouveau tutoriel
  description: |
    La dernière chose à faire est d'annoncer le nouveau tutoriel
    sur le groupe Facebook et le forum Scrivener.
  support:
    - hname: Être assisté pour produire les annonces
      command: annonces %{name}
    - hname: Rejoindre le groupe Facebook
      command: groupe_facebook
    - hname: Rejoindre le forum Scrivener
      command: forum_scrivener
    - hname: Annonce sur Facebook
      command: annonce type=fb %{name}
    - hname: Annonce sur le forum Scrivener
      command: annonce type=scriv %{name}
    - hname: Rejoindre site perso
      command: annonce type=perso %{name}
  produit: null
  informations:
    - annonce_fb
    - annonce_scriv
    - annonce_perso

YAML
