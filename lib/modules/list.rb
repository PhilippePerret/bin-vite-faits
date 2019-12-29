# encoding: UTF-8
class ViteFait
  class List

    # Retourne le nom de tutoriel le plus proche de +name+
    def get_nearer_from_name(name)
      candidats = []
      # puts "Items : #{items.inspect}"
      items.each do |item, ditem|
        ditem[:levenstein] = String.levenshtein_beween(name, items)
        if item.start_with?(name)
          ditem[:presence] = 3
        elsif item.include?(name)
          ditem[:presence] = 2
        else
          ditem[:presence] = 0
        end
        ditem[:similarity] = (ditem[:presence] * 100) - ditem[:levenstein]
        candidats << ditem
      end

      candidats = candidats.sort_by{|ditem| -ditem[:similarity] }
      candidat = candidats.first

      return candidat
    end

    # Retourne la liste complète des tutoriels
    # C'est une table avec en clé le nom du dossier
    def items
      @items ||= begin
        table = {}
        # Rechercher dans tous les dossiers possibles
        DATA_LIEUX.each do |klieu, dlieu|
          path = eval("VITEFAIT_#{klieu.to_s.upcase}_FOLDER")
          dlieu[:path] = path
          dlieu[:tutoriels] = Dir["#{path}/*"].collect{|p|File.basename(p)}
          dlieu[:tutoriels].each do |tutoriel|
            ptuto = File.join(path,tutoriel)
            dtuto = {name:tutoriel, path:ptuto}
            table.merge!( tutoriel => {
              name:   tutoriel,
              lieu:   klieu,
              path:   ptuto,
              date:   getDateFor(dtuto),
              titre:  getTitreFor(dtuto),
              logic_step:getLogicStepFor(dtuto)
              })
          end
        end
        table
      end
    end

    # Affichage de la liste des tutoriels
    # Commande : vite-faits list[e]
    def display
      clear

      key_sort = (COMMAND.params[:sort]||'').downcase
      inverse = key_sort.start_with?('i')

      # = TRI DES TUTORIELS =
      # =====================
      # Si le paramètres ':sort' est défini, il faut classer la liste des
      # item
      template_line = "- %{name} (%{lieu}) - %{logic_step}"
      sorted_items =
        case key_sort
        when 'date', 'idate'
          sort_hname = inverse ? "depuis les plus récents" : "depuis les plus anciens"
          template_line = "%{date} - %{name} (%{lieu})"
          items.values.sort_by { |d| d[:date] }
        when 'name', 'iname'
          sort_hname = "par nom"
          sort_hname << " inversé" if inverse
          items.values.sort_by { |d| d[:name].downcase }
        when 'titre', 'ititre'
          sort_hname = "par titre"
          sort_hname << " inverse" if inverse
          template_line = "%{titre} (%{lieu} — %{name})"
          items.values.sort_by { |d| d[:titre].downcase}
        when 'dev', 'developpement', 'development'
          sort_hname = "par développement"
          sort_hname << " inverse" if inverse
          template_line = "%{titre} (%{lieu} — %{name}) - %{logic_step}"
          items.values.sort_by { |d| - d[:logic_step] }
        else
          sort_hname = "naturel"
          items.values
        end
      sorted_items = sorted_items.reverse if inverse

      # = AFFICHAGE DE LA LISTE =
      # =========================

      puts "  === LISTE DES TUTORIELS (classement #{sort_hname}) ===\n\n"

      sorted_items.each_with_index do |ditem, index|
        tutoline = TutoLine.new(ditem)
        puts ' ' + tutoline.line(template_line)
      end
      puts "\n\n"
    end


    # Retourne le titre du tutoriel de données minimales +dtuto+
    def getTitreFor(dtuto)
      dtuto[:titre] ||= getInfosFor(dtuto)[:titre][:value]
    end

    # Retourne la date de dernière modification du tutoriel de données
    # minimales +dtuto+
    def getDateFor(dtuto)
      # puts "dtuto = #{dtuto.inspect}"
      mtime = File.stat(dtuto[:path]).mtime.to_i
      infos_tuto = getInfosFor(dtuto)
      if infos_tuto[:updated_at] && mtime < infos_tuto[:updated_at]
        return infos_tuto[:updated_at]
      else
        return mtime
      end
    end

    # Retourne l'étape logique du tutoriel défini par +d+
    # Si elle n'est pas encore définie dans les informations du tutoriel,
    # on la cherche et on l'enregistre.
    def getLogicStepFor(dtuto)
      if getInfosFor(dtuto)[:logic_step]
        getInfosFor(dtuto)[:logic_step][:value]
      else
        ViteFait.require_module('conception')
        ViteFait.new(dtuto[:name]).conception.save_last_logic_step
      end
    end

    def getInfosFor(dtuto)
      path = File.join(dtuto[:path],'infos.json')
      if File.exists?(path)
        JSON.parse(File.read(path).force_encoding('utf-8')).to_sym
      else
        {}
      end
    end

    # ---------------------------------------------------------------------
    #   Classe ViteFait::List::TutoLine
    #   Pour gérer plus facilement l'affichage des tutoriels
    class TutoLine
      LEN_STEPS = 13
      LEN_DATE  = 12
      LEN_LIEU  = 18
      class << self
        def titre_len
          @titre_len ||= begin
            IOConsole.width - (5 + LEN_STEPS + LEN_DATE + LEN_LIEU + 3)
          end
        end
      end # /<< self
      attr_reader :data
      def initialize data # data = données minimales
        @data = data
      end

      # La ligne finale à afficher
      def line template
        "#{mark_logic_step} #{mark_titre} #{mark_lieu} #{mark_date}"
      end

      def mark_titre
        @mark_titre ||= begin
          str = titre || name
          if str.length >= self.class.titre_len
            str = str[0..self.class.titre_len - 3]+'…'
          end
          str.ljust(self.class.titre_len)
        end
      end

      def mark_date
        @mark_date ||= begin
          (date || '').ljust(LEN_DATE)
        end
      end

      def mark_lieu
        @mark_lieu ||= begin
          lieu[:short_hname].ljust(LEN_LIEU)
        end
      end
      def mark_logic_step
        @mark_logic_step ||= begin
          stars_on  = "*" * logic_step
          if logic_step < LEN_STEPS
            stars_off = "*" * (LEN_STEPS - logic_step)
          else
            stars_off = ''
          end
          "\033[1;32m#{stars_on}\033[0m\033[1;90m#{stars_off}\033[0m"
        end
      end

      def name ;  @name   ||= data[:name]   end
      def lieu ;  @lieu   ||= DATA_LIEUX[data[:lieu]] end
      def date ;  @date   ||= data[:date] && Time.at(data[:date]).strftime("%d %m %Y") end
      def titre;  @titre  ||= data[:titre]  end
      def logic_step;  @logic_step  ||= data[:logic_step]  end

    end #/ViteFait::List::TutoLine

  end #/List


end#/ViteFait
