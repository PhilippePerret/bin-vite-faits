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
            table.merge!( tutoriel => {
              name: tutoriel,
              lieu: klieu,
              path: ptuto,
              logic_step:getLogicStepFor({name:tutoriel, path:ptuto})
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

      # Si le paramètres ':sort' est défini, il faut classer la liste des
      # item
      template_line = "- %{name} (%{lieu}) - %{logic_step}"
      sorted_items =
        case key_sort
        when 'date', 'idate'
          sort_hname = inverse ? "depuis les plus récents" : "depuis les plus anciens"
          template_line = "%{date} - %{name} (%{lieu})"
          items.values.sort_by { |d| d[:date] ||= getDateFor(d)}
        when 'name', 'iname'
          sort_hname = "par nom"
          sort_hname << " inversé" if inverse
          items.values.sort_by { |d| d[:name].downcase }
        when 'titre', 'ititre'
          sort_hname = "par titre"
          sort_hname << " inverse" if inverse
          template_line = "%{titre} (%{lieu} — %{name})"
          items.values.sort_by { |d| (d[:titre] ||= getTitreFor(d)).downcase}
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

      puts "  === LISTE DES TUTORIELS (classement #{sort_hname}) ===\n\n"

      sorted_items.each_with_index do |ditem, index|
        data_template = {
          name: ditem[:name],
          lieu: DATA_LIEUX[ditem[:lieu]][:hname],
          date: (ditem[:date] && Time.at(ditem[:date]).strftime("%d %m %Y")),
          titre: (ditem[:titre]||ditem[:name]),
          logic_step: (ditem[:logic_step])
        }
        puts "\t#{template_line % data_template}"
      end
      puts "\n\n"
    end


    # Retourne le titre du tutoriel de données minimales +dtuto+
    def getTitreFor(dtuto)
      dtuto[:titre] ||= getInfosFor(dtuto)[:titre] || dtuto[:name]
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
  end #/List
end#/ViteFait
