# encoding: UTF-8
=begin
  Module de raccourcissement des vidéos et des sons

  Ajout de nouveaux fichiers
  --------------------------
  Pour ajouter de nouveaux fichiers, on doit définir
    - une lettre pour les choisir
    - ajouter ses données à la constante DATA_CROPPABLE_FILES
      ci-dessous, tout le reste sera géré automatiquement

=end
class ViteFait

  DATA_CROPPABLE_FILES = [
    {letter: 'V', rpath: 'Operations/capture.mov',  param: 'mov'},
    {letter: 'P', rpath: 'Operations/capture.mp4',  param: 'mp4'},
    {letter: 'X', rpath: 'Voix/voice.mp4',          param: 'voix'},
    {letter: 'T', rpath: 'Titre/titre.mov',         param: 'titre'},
    {letter: 'M', rpath: 'Titre/titre.mp4',         param: 'titmp4'}
  ]
  h = {}
  DATA_CROPPABLE_FILES.each do |dfile|
    h.merge!(dfile[:letter] => dfile[:param])
  end
  CROPPABLE_LETTER_TO_PARAM = h
  # Pour obtenir le path en fonction du paramètre
  h = {}
  DATA_CROPPABLE_FILES.each do |dfile|
    h.merge!(dfile[:param] => dfile[:rpath])
  end
  CROPPABLE_PARAM_TO_PATH = h


  MSG({
    duree_required: "Durée à obtenir non définie (interactivement ou avec 'duree=\"h:mm:ss\"')",
    any_croppable_file: "Aucun fichier croppable n'existe encore pour ce tutoriel…",
    bad_choix_croppable: "Je ne comprends pas ce choix. Je dois renoncer.",
    file_for_crop_required: "Il faut indiquer explicitement le fichier à réduire avec le paramètre 'pour=[mov|mp4|voix]'…",
    file2crop_unfound: "Le fichier à cropper est introuvable…\n(*)",
    duree_exceeds: "La durée à obtenir doit être inférieure à la durée de la vidéo, voyons…",
    dropat_required: "Il faut définir s'il faut raboter par le début ou la fin !",
    unknown_drop_at: "Ce lieu de rabotage est inconnu…"
    })


  def puts_line label, value
    notice "#{label.to_s.ljust(20,'.')} #{value}"
  end
  # Raccourcissement du fichier de capture des opérations
  #
  # La méthode a besoin de :
  #   - le fichier à réduire
  #   - la durée finale à obtenir
  #   - par quel bout réduire (début ou fin)
  def exec_crop
    # - requis -
    begin
      clear
      notice "=== Raccourcissement de fichier son/vidéo ==="
      # file2crop est le fichier à cropper
      file2crop || return
      puts_line('Fichier', relative_pathof(file2crop))
      puts_line('Durée', file2crop_duree)
      duree_crop  || return
      puts_line('Nouvelle durée', duree_crop)
      drop_at || return
      puts_line('Raboter', drop_at == 'start' ? 'au début' : 'à la fin')

      puts_line('Départ rabot', horloge_start)
      puts_line('Durée rabot',  duree_crop.as_horloge)

      # Tout est OK, on peut procéder à l'opération
      cmd = "ffmpeg -i \"#{file2crop_copie}\""
      cmd << " -ss #{horloge_start} -t #{duree_crop.as_horloge}"
      cmd << " \"#{file2crop}\""
      COMMAND.options[:verbose] || cmd << " 2> /dev/null"
      begin
        notice "Rabotage en cours, merci de patienter…"
        IO.remove_with_care(file2crop,'original',false)
        res = `#{cmd}`
      rescue Exception => e
        error "Problème avec la commande :"
        error "#{cmd}"
        error "Impossible de raboter le fichier."
        raise e
      end

      if IO.check_existence(file2crop,{interactive:false}) && Video.dureeOf(file2crop).to_i == duree_crop
        notice "Le fichier a été raboté avec succès ! 👍"
      elsif IO.check_existence(file2crop)
        return error("🖐  Le fichier n'a pas pu être raboté d'autant qu'on le voulait…")
      else
        return error("🖐  Le fichier n'a pas pu être reproduit…")
      end

      # On peut procéder à la destruction des éléments suivants
      # pour pouvoir forcer l'actualisation
      remove_logic_files_after(file2crop)

    rescue Exception => e
      if msg_exists?(e.message.to_sym)
        raise NotAnError.new(MSG(e.message.to_sym))
      else
        # puts "L'ID message '#{e.message.to_sym}' est inconnu"
        raise e
      end
    ensure
      unless @file2crop_copie.nil?
        File.unlink(file2crop_copie) if File.exists?(file2crop_copie)
      end
    end
  end

  # Méthode qui se charge de détruire les fichiers logiques
  # après le fichier +file+
  # Les "fichiers logiques" sont les fichiers qui dépendent
  # du fichier +file+ (i.e. qui sont assemblés d'après lui)
  def remove_logic_files_after file
    notice "* Destruction des fichiers logiques de “#{name}” après le fichier raboté…"
    notice "  (pour pouvoir actualiser la sortie finale)"
    pth = self.relative_pathof(file)
    liste = []
    # Dans tous les cas, il faut détuire la vidéo finale
    liste << "Exports/#{final_tutoriel_mp4_name}"
    case 'pth'
    when './Voix/voice.mov'
      liste << 'Voix/voice.mp4'
      liste << 'Voix/voice.aac'
      liste << 'Voix/voice.aiff'
    when './Voix/voice.mp4'
      liste << 'Voix/voice.aac'
      liste << 'Voix/voice.aiff'
    when './Titre/Titre.mov'
      liste << 'Titre/Titre.mp4'
      liste << 'Titre/Titre.ts'
    when './Titre/Titre.mp4'
      liste << 'Titre/Titre.ts'
    when './Operations/capture.mov'
      liste << 'Operations/capture.mp4'
    when './Operations/capture.mp4'
      # Rien à faire ici
    end
    liste.each do |relpath|
      IO.remove_with_care(pathof(relpath),"fichier #{relpath}",interactive = true)
    end
    notice <<-EOT

Relance l'assemblage de “#{name}” pour actualiser
la sortie finale :

    vitefait assemble #{name}

    EOT

  end


  # Retourne l'horloge de départ en fonction du drop_at
  def horloge_start
    @horloge_start ||= begin
      if drop_at == 'start'
        (file2crop_duree - duree_crop).to_i.as_horloge
      else # drop_at == 'end'
        '00:00:00'
      end
    end
  end

  def file2crop_duree
    @file2crop_duree ||= Video.dureeOf(file2crop)
  end

  # Retourne le path copie pour le fichier copié
  # C'est aussi la méthode qui produit la copie
  def file2crop_copie
    @file2crop_copie ||= begin
      fold = File.dirname(file2crop)
      exte = File.extname(file2crop)
      affi = File.basename(file2crop, exte)
      file2crop_copie = File.join(fold, "#{affi}~copie.#{exte}")
      FileUtils.copy(file2crop, file2crop_copie) # on fait la coppie
      file2crop_copie
    end
  end
  # Retourne le fichier à cropper (ou false en cas d'erreur)
  def file2crop
    @file2crop ||= begin
      f2s = if COMMAND.params[:pour]
              get_file2crop_from_pour(COMMAND.params[:pour])
            else
              ask_for_file_to_crop
            end
      f2s || raise('file_for_crop_required')
      File.exists?(f2s) || raise('file2crop_unfound')
      f2s
    end
  end

  # Retourne la durée (valide) à cropper
  def duree_crop
    @duree_crop ||= begin
      cduree =  if COMMAND.params[:duree]
                  COMMAND.params[:duree]
                else
                  ask_for_duree_crop(file2crop)
                end
      # Est-ce que la durée est valide ?
      cduree || raise('duree_required')
      cduree = cduree.h2s
      cduree < Video.dureeOf(file2crop) || raise('duree_exceeds')
      cduree
    end
  end

  # Retourne par où il faut couper, le début ('start') ou la fin ('end')
  def drop_at
    @drop_at ||= begin
      da =  if COMMAND.params[:from]
              COMMAND.params[:from] # 'start' ou 'end'
            else
              ask_for_crop_at
            end
      da || raise('dropat_required')
      ['start','end'].include?(da) || raise('unknown_drop_at')
      da
    end
  end

  def ask_for_duree_crop(file2crop)
    duree = Video.dureeOf(file2crop).to_i.as_horloge
    prompt("Quelle durée (horloge) doit faire le fichier '#{File.basename(file2crop)}' à cropper (durée actuelle : #{duree}) ?")
  end


  def ask_for_file_to_crop
    liste = []
    DATA_CROPPABLE_FILES.each do |dfile|
      File.exists?(pathof(dfile[:rpath])) && liste << "#{dfile[:letter]} = #{dfile[:rpath]}"
    end
    @croppable_files = liste
    if liste.empty?
      raise 'any_croppable_file'
    elsif liste.count == 1
      notice "Il n'existe qu'un candidat pour ce crop : #{liste.first}. Je le prends."
      choix = liste.first[0]
    else
      puts <<-EOT

  Fichier de “#{name}” à raccourcir :

    #{liste.join("\n    ")}

  (noter que les fichiers qui découlent du fichier choisi
   seront détruits pour forcer la reconstruction)

      EOT
      choix = getChar("Fichier à cropper : ").upcase
    end
    if CROPPABLE_LETTER_TO_PARAM.key?(choix)
      get_file2crop_from_pour(CROPPABLE_LETTER_TO_PARAM[choix])
    else
      raise 'bad_choix_croppable'
    end
  end #/ask_for_file_to_crop

  def ask_for_crop_at
    choix = getChar("Raboter par le début (S) ou par la fin (E) ?") || return
    case choix.upcase
    when 'S'  then 'start'
    when 'E'  then 'end'
    else
      error "Je ne connais pas le choix '#{choix}'."
      return
    end
  end

  def get_file2crop_from_pour(pour)
    if CROPPABLE_PARAM_TO_PATH.key?(pour)
      pathof(CROPPABLE_PARAM_TO_PATH[pour])
    else
      raise "Le fichier à cropper désigné par “#{pour}” n'est pas défini…"
    end
  end
end #/ViteFait
