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
  def set params
    hasBeenModified = false
    params.each do |ikey, new_value|
      data.key?(ikey) || next # pour ne prendre que les infos pertinentes
      idata = data[ikey]
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
      puts "\t"+ikey.to_s.ljust(20) + idata[:value].inspect
    end
    puts "\n\nPour modifier ces informations : `vite-faits infos #{vitefait.name} <clé>=<valeur>`"
    puts data.inspect
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
