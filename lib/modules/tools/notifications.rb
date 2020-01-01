# encoding: UTF-8
=begin
  Module pour la gestion des notifications du tutoriel
=end
class ViteFait

  # Instance de la liste des notifications
  def notifications
    @notifications ||= Notifications.new(self)
  end


  # = main =
  # Traitement principal de la commande 'notifications'
  def exec_commande_notifications
    # On affiche toujours la liste des notifications
    clear
    notifications.wait_for_choix_and_execute
  end

  # ---------------------------------------------------------------------
  #   Class ViteFait::Notifications
  #   Gestion des notifications comme un ensemble d'instance Notification
  # ---------------------------------------------------------------------
  class Notifications

    # Pour la méthode `set`, on peut utiliser ces paramètres/clés
    # réduites. Par exemple :
    #   set 4 m="Mon nouveau content" d="Ma nouvelle description"
    SHORT_KEY_TO_REAL_KEY = {
      'm' => 'message',
      't' => 'titre',
      'd' => 'date'
    }

    attr_reader :tuto
    def initialize tuto
      @tuto = tuto
    end

    # Affichage des notifications
    # +Params+
    #   +options+:: {Hash}
    #     :all    Si true, on doit afficher toute les notifications
    def display options = {}

      # Retirer ce clear pour voir tous les messages
      clear

      notice <<-EOT
=== LISTE DES NOTIFICATIONS ===
(pour “#{tuto.titre || tuto.name}”)
      EOT
      if itemsById.empty?
        puts "--- Aucune notification pour le moment ---"
      else
        puts header(options)
        listing.each { |notify| notify.display(options)}
      end
      display_commandes
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
        when 'done', 'set', 'remove', 'delete'
          # Toutes les commandes qui vont appel à un id de notification
          notify_id = should_be_a_notify_id(word2)
        when 'show'
          if word2 == 'all'
            notify_id = :all
          else
            notify_id = should_be_a_notify_id(word2)
          end
        end

        # On étudie la commande
        msg = case commande
              when 'add'
                add(word2, params)
              when 'aide'
                texte_aide
              when 'show', 'montre', 'affiche'
                if notify_id == :all
                  options_display = {all:true}
                  ''
                else
                  show(notify_id) # ou :all
                end
              when 'close', 'done', 'finish'
                finish(notify_id)
              when 'reopen','undone'
                unfinish(notify_id)
              when 'delete', 'remove'
                remove(notify_id)
              when 'set'
                set(notify_id, params)
              end
      rescue NotAnError => e
        msg = e.error_if_message
      end while true #/fin du while
    end

    # Reçoit une +date+ avec un format quelconque et des
    # délimitateurs balance ou espace, et retourne une
    # date bien formatée
    def readDateIn date
      date = date.split(/[ \/]/)
      if date[0].length == 4
        y, m, d = date
      else
        d, m, y = date
      end
      "#{y} #{m.rjust(2,'0')} #{d.rjust(2,'0')}"
    end

    # Retourne le texte d'aide
    def texte_aide
      <<-EOT
=== Aide pour les notifications ===\033[0m

Ajouter une notification
  #{jaune('add "<notification>" "AAAA MM JJ"[ "titre"]')}

  Note :  la date peut être définie soit par JJ/MM/AAAA,
          soit par JJ MM AAAA, soit 'AAAA MM J' ou
          'AAAA/M/J', peu importe.

Supprimer une notification
  #{jaune('remove/delete <id notification>')}

Voir toutes les informations de la notification
  #{jaune('show <id notification>')}

(Re)définir les attributs d'une notification
  #{jaune('set <id notification> m="message" t="titre" d="AAAA MM JJ"')}

Quitter
  #{jaune('q/quit/quitter')}

      EOT
    end

    def jaune msg
      "\033[1;33m#{msg}\033[0m"
    end

    def should_be_a_notify_id(word2)
      word2.gsub(/[1-9][0-9]?/,'') == '' || raise(NotAnError.new("L'identifiant de la notification (#{word2}) doit être un nombre !"))
      notify_id = word2.to_i
      get(notify_id) || raise(NotAnError.new("La notification ##{notify_id} est inconnue…"))
      notify_id
    end

    def as_error msg
      "\033[1;31m#{msg}\033[0m"
    end

    def get notify_id
      itemsById[notify_id]
    end

    # Renvoie l'affichage complet de la notification
    def show(notify_id)
      if notify_id == :all
        display({all:true})
      else
        get(notify_id).full_display
      end
    end

    # Ajoute une notification
    def add message, params
      nombre_notifications_avant = itemsById.keys.count
      message || raise(NotAnError.new("Il faut définir le message de la notification !"))
      date  = readDateIn(params.shift)
      titre = params.shift # 0 si non défini
      notify = Notification.new({id:new_id, message:message, titre:titre, date:date}, self)
      itemsById.merge!(notify.id => notify)
      save
      if itemsById.keys.count == nombre_notifications_avant + 1
        "Notification ajoutée avec succès."
      else
        as_error("Bizarrement, la notification ne semble pas avoir été ajoutée…")
      end
    end

    # Redéfinir une notify
    def set(notify_id, params)
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
        new_data.merge!(key => value)
        new_data.merge!(:date => readDateIn(new_data[:date])) if new_data.key?(:date)
        get(notify_id).dispatch(new_data)
        save
      end
      "Notification redéfinie avec succès."
    end

    def remove notify_id
      count_init = itemsById.count
      itemsById.delete(notify_id)
      save
      if itemsById.count == count_init - 1
        "Notification détruite avec succès"
      else
        as_error "Impossible de détruire la notification, apparemment…"
      end
    end

    def finish notify_id
      get(notify_id).done = Time.now.to_i
      save
    end

    def unfinish notify_id
      get(notify_id).done = nil
      save
    end

    # Enregistre les notifications
    def save
      data2save = itemsById.values.collect{|notify|notify.data}
      File.open(path,'wb'){|f| f.write YAML.dump(data2save)}
      @itemsById = nil
    end

    def listing(options = {})
      itemsById.values
    end

    def header options = {}
      m = " ".ljust(Notification::INDENT_LEN)+
          "ID".ljust(Notification::MARK_ID_LEN)+
          "Notification".ljust(Notification::MESSAGE_LEN)+
          ' '+"Titre".ljust(Notification::MARK_TITRE_LEN,'.')+
          ' '+"Date".rjust(Notification::MARK_DATE_LEN,'.')
      m += "\n"
      return m
    end

    # Affichage des commandes de la prompt notifications
    def display_commandes
      puts <<-EOT

(Taper 'aide' pour obtenir de l'aide)

      EOT
    end

    # Table {Hash} des instances de notifications, avec en clé leur identifiant
    def itemsById
      @itemsById ||= begin
        @last_id = 0
        h = {}
        if File.exists?(path)
          YAML.load_file(path).to_sym.each do |data_notify|
            notify = Notification.new(data_notify, self)
            @last_id = notify.id if notify.id > @last_id
            h.merge!(notify.id => notify)
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
      @path ||= tuto.pathof('notifications.yaml')
    end

  end #/ViteFait::Notifications
end #/ViteFait


class Notification

  MESSAGE_LEN = 50
  INDENT_LEN = 6
  MARK_ID_LEN = 4
  MARK_TITRE_LEN = 20
  MARK_DATE_LEN = 13

  # Affichage de la notification dans le listing des notifications
  # +Params+
  #   +options+:: [Hash] Options pour le format de sortie.
  #     :simple     Affichage simple, avec seulement l'identifiant de
  #                 la notification et son libellé.
  def display options = {}
    line = "#{indentation}#{mark_id}#{f_message} #{f_titre} #{f_date}"
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
    "##{id}".ljust(MARK_ID_LEN)
  end

  # Affichage complet
  def full_display options = {}
    return "\n\n#{indentation}##{id.to_s.ljust(2)} #{message}\033[0m\n#{long_indent}#{titre}\n#{long_indent}-----------------\n#{long_indent}#{f_fulldate}"
  end

  def f_message
    if message.length < MESSAGE_LEN
      message
    else
      message[0..MESSAGE_LEN-3] + '…'
    end.ljust(MESSAGE_LEN)
  end

  def f_titre
    @titre ||= 'Notification'
    if titre.length < MARK_TITRE_LEN
      titre
    else
      titre[0..MARK_TITRE_LEN-3] + '…'
    end.ljust(MARK_TITRE_LEN)
  end

  def f_date
    y,m,d = date.split(' ')
    "#{d.to_i} #{String::MOIS[m.to_i][:short]} #{y}".rjust(MARK_DATE_LEN)
  end
  def f_fulldate
    y,m,d = date.split(' ')
    "#{d} #{String::MOIS[m.to_i][:long]} #{y}"
  end
end #/ViteFait::Notifications::Notification
