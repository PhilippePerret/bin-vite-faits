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
    titre:          {value:nil,   editable:true,  required:true,  type: 'string'},
    titre_en:       {value:nil,   editable:true,  required:true,  type: 'string'},
    description:    {value:nil,   editable:true,  required:true,  type: 'string'},
    youtube_id:     {value:nil,   editable:true,  required:true,  type: 'string'},
    accelerator:    {value:nil,   editable:true,  required:false, type: 'float'},
    logic_step:     {value:nil,   editable:false, required:false, type: 'integer'},
    site_perso:     {value:false, editable:false, required:false, type: 'boolean'},
    uploaded:       {value:false, editable:false, required:false, type: 'boolean'},
    annonce_FB:     {value:false, editable:false, required:false, type: 'boolean'},
    annonce_Scriv:  {value:false, editable:false, required:false, type: 'boolean'},
    published_at:   {value: nil,  editable:true,  required:true,  type: 'string'},
    updated_at:     {value:nil,   editable:false, required:false, type: 'integer'},
    created_at:     {value:nil,   editable:false, required:false, type: 'integer'}
  }

  # Nom alternatif des propriétés pour les infos
  ALT_INFO_KEY_TO_REAL_KEY = {
    publication: :published_at
  }


  # ---------------------------------------------------------------------
  #   CLASSE
  # ---------------------------------------------------------------------
  class << self

    # Return +true+ si la date +date+ est valide.
    def published_date_valid?(date)
      j,m,a = date.split(' ')
      begin
        inst = Date.parse("#{a}/#{m}/#{j}")
      rescue Exception => e
        error "La date de publication (#{date}) est mal formatée (attendu : 'JJ MM AAAA') : #{e.message}."
        return false
      end
      if inst < Date.today
        error "La date de publication doit être dans le futur, voyons…"
        return false
      end
      return true
    end


  end # << self

  # ---------------------------------------------------------------------
  #   INSTANCE
  # ---------------------------------------------------------------------

  attr_reader :vitefait

  def initialize vitefait
    @vitefait = vitefait
  end

  # Retourne la valeur de l'information de clé +key+
  #
  # Pour pouvoir utiliser la formule <ViteFait>#informations[key]
  def [] key
    key = ALT_INFO_KEY_TO_REAL_KEY[key] || key
    data[key] || begin
      DEFAULT_INFORMATIONS.key?(key) || raise("La clé '#{key}' est inconnue des informations du tutoriel…")
      data.merge!(key => DEFAULT_INFORMATIONS[key])
    end
    data[key][:value]
  end

  # Pour définir la valeur de l'information +key+ avec +value+
  def []= key, value
    key = key.to_sym
    key = ALT_INFO_KEY_TO_REAL_KEY[key] || key
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
    notice "Informations sur le tutoriel “#{vitefait.name}” enregistrées avec succès."
  end

  # Définition des données
  # Note : la méthode sauve les données si elles ont changé.
  def set params
    hasBeenModified = false
    params.each do |ikey, new_value|
      ikey = ALT_INFO_KEY_TO_REAL_KEY[ikey] || ikey
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
      # En fonction du type, il faut changer la valeur
      new_value =
        case DEFAULT_INFORMATIONS[ikey][:type]
        when 'string'   then new_value != '' ? new_value : nil
        when 'boolean'  then new_value === 'true' || new_value === '1'
        when 'integer'  then new_value.to_i
        when 'float'    then new_value.to_f
        end

      # On poursuit seulement si la nouvelle valeur est différente
      # de la valeur actuelle
      data[ikey][:value] != new_value || next # pas de modification

      # Validité de la nouvelle valeur
      # ------------------------------
      case ikey
      when :uploaded
        if  new_value === true
          if vitefait.video_on_youtube?
            notice "J'ai trouvé la vidéo sur YouTube, super !"
          else
            return error("Je n'ai pas trouvé la vidéo sur YouTube, je ne peux pas mettre loaded à true.")
          end
        end
      when :published_at
        Informations.published_date_valid?(new_value) || next
      end

      # Tout est bon, on peut consigner cette valeur
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
