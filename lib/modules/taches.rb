# encoding: UTF-8
=begin
  Module pour la gestion des tâches du tutoriel
=end
class ViteFait

  # Instance de la liste des taches
  def taches
    @taches ||= Taches.new(self)
  end


  # = main =
  # Traitement principal de la commande 'taches'
  def exec_commande_taches
    # On affiche toujours la liste des tâches
    clear
    taches.wait_for_choix_and_execute
  end

  # ---------------------------------------------------------------------
  #   Class ViteFait::Taches
  #   Gestion des tâches comme un ensemble d'instance Tache
  # ---------------------------------------------------------------------
  class Taches

    # Pour la méthode `set`, on peut utiliser ces paramètres/clés
    # réduites. Par exemple :
    #   set 4 m="Mon nouveau content" d="Ma nouvelle description"
    SHORT_KEY_TO_REAL_KEY = {
      'm' => 'content',
      'd' => 'description',
      'p' => 'priority'
    }

    attr_reader :tuto
    def initialize tuto
      @tuto = tuto
    end

    # Méthode qui affiche la prompt et la traite
    def wait_for_choix_and_execute
      msg = nil
      options_display = {}
      begin
        display(options_display)
        msg && notice(msg)
        commande = prompt("\n:::") || return
        # On récupère les strings
        strings = []
        commande.gsub!(/(?!\\)"(.*?)(?!\\)"/){
          strings << $1.to_s
          "__STRING#{strings.count - 1}STRING__"
        }
        params = commande.split(' ').collect do |seg|
          if seg.match(/__STRING([0-9]+)STRING__/)
            seg.gsub(/__STRING([0-9]+)STRING__/){strings[$1.to_i]}
          else
            seg
          end
        end
        msg  = params.inspect
        commande = params.shift
        word2 = params.shift
        case commande
        when 'q', 'quit', 'quitter'
          return
        when 'add', 'aide', 'help'
          # On suit
        when 'close', 'done', 'set', 'remove', 'delete', 'undone', 'reopen'
          # Toutes les commandes qui vont appel à un id de tâche
          tache_id = should_be_a_tache_id(word2)
        when 'show'
          if word2 == 'all'
            tache_id = :all
          else
            tache_id = should_be_a_tache_id(word2)
          end
        end

        # On étudie la commande
        msg = case commande
              when 'add'
                add(word2, params)
              when 'aide'
                texte_aide
              when 'show', 'montre', 'affiche'
                if tache_id == :all
                  options_display = {all:true}
                  ''
                else
                  show(tache_id) # ou :all
                end
              when 'close', 'done', 'finish'
                finish(tache_id)
              when 'reopen','undone'
                unfinish(tache_id)
                "Tâche terminée avec succès."
              when 'delete', 'remove'
                remove(tache_id)
              when 'set'
                set(tache_id, params)
              end
      rescue NotAnError => e
        msg = e.error_if_message
      end while true #/fin du while
    end

    # Retourne le texte d'aide
    def texte_aide
      <<-EOT
=== Aide pour les tâches ===\033[0m

Ajouter une tâche (avec ou sans description)
  #{jaune('add "<tâche>"[ "description"][ <priorité>]')}
  La priorité est un nombre de 0 (aucune priorité) à
  9 (priorité maximale).

Marquer une tâche finie
  #{jaune('close/done <id tâche>')}

Voir toutes les informations de la tâche
  #{jaune('show <id tâche>')}

(Re)définir les attributs d'une tâche
  #{jaune('set <id tâche> m="contenu" d="description" p=[0-9]')}
  p pour la priorité (0 par défaut)

Détruire une tâche
  #{jaune('remove/delete <id tâche>')}

Quitter
  #{jaune('q/quit/quitter')}

      EOT
    end

    def jaune msg
      "\033[1;33m#{msg}\033[0m"
    end

    def should_be_a_tache_id(word2)
      word2.gsub(/[1-9][0-9]?/,'') == '' || raise(NotAnError.new("L'identifiant de la tâche (#{word2}) doit être un nombre !"))
      tache_id = word2.to_i
      get(tache_id) || raise(NotAnError.new("La tâche ##{tache_id} est inconnue…"))
      tache_id
    end

    def as_error msg
      "\033[1;31m#{msg}\033[0m"
    end

    def get tache_id
      itemsById[tache_id]
    end

    # Renvoie l'affichage complet de la tâche
    def show(tache_id)
      if tache_id == :all
        display({all:true})
      else
        get(tache_id).full_display
      end
    end

    # Ajoute une tâche
    def add content, params
      nombre_taches_avant = itemsById.keys.count
      content || raise(NotAnError.new("Il faut définir le contenu de la tâche !"))
      description = params.shift
      priority    = params.shift.to_i # 0 si non défini
      tache = Tache.new(self, {content:content, description:description, priority:priority})
      itemsById.merge!(tache.id => tache)
      save
      if itemsById.keys.count == nombre_taches_avant + 1
        "Tâche ajoutée avec succès."
      else
        as_error("Bizarrement, la tâche ne semble pas avoir été ajoutée…")
      end
    end

    # Redéfinir une tache
    def set(tache_id, params)
      # puts "params = #{params.inspect}"
      new_data = {}
      params.each do |paire|
        s = paire.split('=')
        if s.count > 2
          index = paire.index('=')
          key = paire[0...index].strip
          value = paire[index+1..-1].strip
        else
          key, value = s
        end
        key = (SHORT_KEY_TO_REAL_KEY[key] || key).to_sym
        case key
        when :priority
          value = value.to_i
        end
        new_data.merge!(key => value)
        get(tache_id).dispatch(new_data)
        save
      end
      "Tâche redéfinie avec succès."
    end

    def remove tache_id
      count_init = itemsById.count
      itemsById.delete(tache_id)
      save
      if itemsById.count == count_init - 1
        "Tâche détruite avec succès"
      else
        as_error "Impossible de détruire la tâche, apparemment…"
      end
    end

    def finish tache_id
      get(tache_id).done = Time.now.to_i
      save
    end

    def unfinish tache_id
      get(tache_id).done = nil
      save
    end

    # Enregistre les tâches
    def save
      data2save = itemsById.values.collect{|tache|tache.data}
      File.open(path,'wb'){|f| f.write YAML.dump(data2save)}
    end

    # Affichage des tâches
    # +Params+
    #   +options+:: {Hash}
    #     :all    Si true, on doit afficher toute les tâches
    def display options = {}

      # Retirer ce clear pour voir tous les messages
      clear

      notice <<-EOT
=== LISTE DES TÂCHES ===
(pour “#{tuto.titre || tuto.name}”)
      EOT
      if itemsById.empty?
        puts "--- Aucune tâche pour le moment ---"
      else
        puts header(options)
        listing.each { |tache| tache.display(options)}
      end
      display_commandes
    end

    def listing(options = {})
      @listing ||= begin
        itemsById
          .values
          .select  { |tache| options[:all] || !tache.done }
          .sort_by { |tache| -((tache.priority.to_i + 1) * tache.created_at) + tache.created_at}
      end
    end

    def header options = {}
      m = " ".ljust(Tache::INDENT_LEN)+
          "ID".ljust(Tache::MARK_ID_LEN)+
          "Tâche".ljust(Tache::CONTENT_LENGTH)+
          "Desc?".ljust(Tache::MARK_DESCRIPTION_LEN)+
          "Prior.".ljust(Tache::MARK_PRIORITY_LEN)
      options[:all] && m << "Finie le".ljust(Tache::MARK_DONE_LEN)
      m += "\n"
      return m
    end

    # Affichage des commandes de la prompt taches
    def display_commandes
      puts <<-EOT

(Taper 'aide' pour obtenir de l'aide)

      EOT
    end

    # Table {Hash} des instances de tâches, avec en clé leur identifiant
    def itemsById
      @itemsById ||= begin
        @last_id = 0
        h = {}
        if File.exists?(path)
          YAML.load_file(path).to_sym.each do |data_tache|
            tache = Tache.new(self, data_tache)
            @last_id = tache.id if tache.id > @last_id
            h.merge!(tache.id => tache)
          end
        end
        h
      end
    end

    # Retourne un identifiant libre
    def new_id
      @last_id ||= 0
      @last_id += 1
    end

    def path
      @path ||= tuto.pathof('Assets/taches.yaml')
    end

    # ---------------------------------------------------------------------
    #   Class ViteFait::Taches::Tache
    #   Instance de chaque tâche
    # ---------------------------------------------------------------------

    class Tache

      CONTENT_LENGTH = 50
      INDENT_LEN = 6
      MARK_ID_LEN = 4
      MARK_DESCRIPTION_LEN = 6
      MARK_PRIORITY_LEN = 8
      MARK_DONE_LEN = 18


      attr_reader :itaches
      attr_reader :data, :id, :content, :created_at, :description
      attr_reader :done, :priority

      def initialize itaches, data
        @itaches = itaches
        @data = data
        dispatch
        @id || init
      end

      def dispatch(new_data = nil)
        new_data ||= data
        new_data.each do |k,v|
          instance_variable_set("@#{k}", v)
          # La version formatée
          instance_variable_set("@f_#{k}", nil)
          # La marque éventuelle
          instance_variable_set("@mark_#{k}", nil)
        end
        @data = data.merge!(new_data)
        # puts "Nouvelles données de ##{id}: #{data.inspect}"
      end

      def init
        # nouvelle tâche
        @id = itaches.new_id
        @created_at = Time.now.to_i
        @priority ||= 0
        @data.merge!({
          id: @id, created_at:@created_at, priority:@priority, done:nil
          })
      end

      # Affichage de la tâche dans le listing des tâches
      # +Params+
      #   +options+:: [Hash] Options pour le format de sortie.
      #     :simple     Affichage simple, avec seulement l'identifiant de
      #                 la tâche et son libellé.
      def display options = {}
        line = "#{indentation}#{mark_id}#{f_content.ljust(CONTENT_LENGTH)}"
        unless options[:format] == :simple
          # line << "#{mark_description.ljust(MARK_DESCRIPTION_LEN)}#{mark_priority.ljust(MARK_PRIORITY_LEN)}"
        end
        if options[:all]
          # Quand c'est l'affichage d'absolument toutes les tâches
          line += "   #{mark_done.ljust(MARK_DONE_LEN)}"
        end
        puts line
      end

      def indentation
        @indentation ||= ' '.ljust(INDENT_LEN)
      end
      alias :indent :indentation

      def long_indent
        @long_indent ||= '    ' + indentation
      end

      def mark_id
        @mark_id ||= "##{id}".ljust(MARK_ID_LEN)
      end

      # Affichage complet
      def full_display options = {}
        return "\n\n#{indentation}##{id.to_s.ljust(2)} #{content}\033[0m\n#{long_indent}#{f_description}\n#{long_indent}-----------------\n#{long_indent}Priorité : #{mark_priority}\n#{long_indent}#{f_created_at}\n#{long_indent}#{f_done}"
      end

      def mark_description
        @mark_description ||= description.to_s == '' ? '  -' : '  x'
      end

      def mark_done
        @mark_done ||= done ? date_done(true) : '    ---'
      end
      def f_content
        @f_content ||= begin
          if content.length < CONTENT_LENGTH
            content
          else
            content[0..CONTENT_LENGTH-2] + '…'
          end
        end
      end

      def f_description
        @f_description ||= begin
          if description.to_s != ''
            description.gsub(/\n/, "\n#{long_indent}").gsub(/\\n/, "\n#{long_indent}").strip
          else
            "- pas de description -"
          end
        end
      end

      def f_created_at
        @f_created_at ||= begin
          "créée le #{Time.at(created_at).strftime('%d %m %Y à %H:%M')}"
        end
      end

      def f_done
        @f_done ||= begin
          if done
            "terminée le #{date_done}"
          else
            "\033[1;31mÀ faire\033[0m"
          end
        end
      end

      def date_done(short = false)
        temp = short ? '%d %m %y à %H:%M' : '%d %m %Y à %H:%M'
        Time.at(done).strftime(temp)
      end

      def done= value
        data[:done] = value
      end

      def priority= value
        data[:priority] = value
      end

      def mark_priority
        @mark_priority ||= "  #{priority||0}"
      end
    end #/ViteFait::Taches::Tache
  end #/ViteFaite::Taches
end #/ViteFait
