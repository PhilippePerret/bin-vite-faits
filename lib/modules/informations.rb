# encoding: UTF-8
=begin
  Classe Informations
  -------------------
  Gestion des informations du tutoriel

  Chaque fois qu'on fait > vite-faits infos <nom-dossier-tuto> on active
  la méthode 'Informations#touch'
=end
class Informations

  DEFAULT_INFORMATIONS = {
    titre:          {value:nil,   editable:true,  required:true},
    titre_en:       {value:nil,   editable:true,  required:true},
    youtube_id:     {value:nil,   editable:true,  required:true},
    description:    {value:nil,   editable:true,  required:true},
    accelerator:    {value:nil,   editable:true,  required:false, method: :to_f},
    logic_step:     {value:nil,   editable:false, required:false, method: :to_i},
    site_perso:     {value:false, editable:false, required:false},
    uploaded:       {value:false, editable:false, required:false},
    annonce_FB:     {value:false, editable:false, required:false},
    annonce_Scriv:  {value:false, editable:false, required:false},
    updated_at:     {value:nil,   editable:false, required:false},
    created_at:     {value:nil,   editable:false, required:false}
  }

  attr_reader :vitefait

  def initialize vitefait
    @vitefait = vitefait
  end

  # Retourne la valeur de l'information de clé +key+
  #
  # Pour pouvoir utiliser la formule <ViteFait>#informations[key]
  def [] key
    data[key] || begin
      DEFAULT_INFORMATIONS.key?(key) || raise("La clé '#{key}' est inconnue des informations du tutoriel…")
      data.merge!(key => DEFAULT_INFORMATIONS[key])
    end
    data[key][:value]
  end

  # Pour définir la valeur de l'information +key+ avec +value+
  def []= key, value
    set({key => value})
  end

  # Méthode appelée dès qu'on joue `vite-faits infos <nom-dossier-tuto>`
  def touch
    if COMMAND.params.keys.count > 0
      set(COMMAND.params)
    else
      display
    end
  end

  # Enregistrement des données
  def save
    data.key?(:created_at) || data.merge!(created_at: Time.now.to_i)
    data.merge!(updated_at: Time.now.to_i)
    File.open(path,'wb'){|f| f.write data.to_json}
    notice "Informations sur le tutoriel enregistrées avec succès."
  end

  # Définition des données
  # Note : la méthode sauve les données si elles ont changé.
  def set params
    hasBeenModified = false
    params.each do |ikey, new_value|
      data.key?(ikey) || begin
        if DEFAULT_INFORMATIONS.key?(ikey)
          # <= Une clé connue des informations par défaut
          # => C'est un vieil enregistrement qui ne connaissait pas cette
          #     information.
          data.merge!(ikey => DEFAULT_INFORMATIONS[ikey])
        else
          error "Je ne connais pas l'information #{ikey.inspect}. Je ne peux\nprendre cette information que si l'option --force\nest activée."
          next # pour ne prendre que les infos pertinentes
        end
      end
      idata = data[ikey] || DEFAULT_INFORMATIONS[ikey]
      if DEFAULT_INFORMATIONS[ikey][:method]
        new_value = new_value.send(DEFAULT_INFORMATIONS[ikey][:method])
      end
      data[ikey][:value] != new_value || next # pas de modification
      data[ikey].merge!(value: new_value)
      hasBeenModified = true
    end
    save if hasBeenModified
  end

  # Affichage des données
  def display
    puts "\n\n"
    data.each do |ikey, idata|
      # puts "ikey: #{ikey} = #{idata.inspect}"
      value = idata.is_a?(Hash) ? idata[:value] : idata
      puts "\t"+ikey.to_s.ljust(20) + value.inspect
    end
    puts "\n\nPour modifier ces informations : `vite-faits infos #{vitefait.name} <clé>=<valeur>`"
    # puts data.inspect
  end

  # Les données
  def data
    @data ||= begin
      if File.exists?(path)
        JSON.parse(File.read(path).force_encoding('utf-8'),symbolize_names:true)
      else
        Informations::DEFAULT_INFORMATIONS
      end
    end
  end

  # path au fichier
  def path
    @path ||= vitefait.pathof('infos.json')
  end
end#/Informations
