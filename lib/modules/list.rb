# encoding: UTF-8
class ViteFait
  class List
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
            table.merge!( tutoriel => {name: tutoriel, lieu: klieu, path:File.join(path,tutoriel)})
          end
        end
        table
      end
    end

    # Affichage de la liste des tutoriels
    #  vite-faits list[e]
    def display
      clear

      key_sort = (COMMAND.params[:sort]||'').downcase
      inverse = key_sort.start_with?('i')

      # Si le paramètres ':sort' est défini, il faut classer la liste des
      # item
      template_line = "- %{name} (%{lieu})"
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
        else
          sort_hname = "naturel"
          items.values
        end

      sorted_items = sorted_items.reverse if inverse

      puts "  === LISTE DES TUTORIELS (classement #{sort_hname}) ===\n\n"

      sorted_items.each_with_index do |ditem, index|
        data_template = {
          name: ditem[:name], lieu: DATA_LIEUX[ditem[:lieu]][:hname],
          date: (ditem[:date] && Time.at(ditem[:date]).strftime("%d %m %Y")),
          titre: (ditem[:titre]||ditem[:name])
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

    def getInfosFor(dtuto)
      path = File.join(dtuto[:path],'infos.json')
      if File.exists?(path)
        JSON.parse(File.read(path).force_encoding('utf-8'))
      else
        {}
      end
    end
  end #/List
end#/ViteFait
