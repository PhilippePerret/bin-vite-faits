describe 'la commande liste/list' do
  it 'retourne la liste de tous les tutoriels' do
    cmd = VFCommand.new('liste')
    o = cmd.output
    expect(o).to include ('=== LISTE DES TUTORIELS')
  end
  it 'retournent la même valeur ("liste" ou "list")' do
    o1 = VFCommand.new('liste').output
    o2 = VFCommand.new('list').output
    expect(o1).to eq(o2)
  end
  it 'contient bien tous les tutoriels sauf ceux terminés' do
    # On va récupérer les tutoriels dans les différents dossiers
    alltutos = []
    [
      VITEFAIT_CHANTIER_FOLDER,
      VITEFAIT_CHANTIERD_FOLDER,
      # VITEFAIT_COMPLETED_FOLDER,
      # VITEFAIT_PUBLISHED_FOLDER,
      VITEFAIT_ATTENTE_FOLDER
    ].each do |folder|
      alltutos += Dir["#{folder}/*"].collect do |p|
        tuto = ViteFait.new(File.basename(p))
        tuto.titre.nil? ? tuto.name[0..20] : tuto.titre[0..20]
      end
    end

    outtutos = []
    [
      VITEFAIT_COMPLETED_FOLDER,
      VITEFAIT_PUBLISHED_FOLDER
    ].each do |folder|
      outtutos += Dir["#{folder}/*"].collect do |p|
        tuto = ViteFait.new(File.basename(p))
        tuto.titre.nil? ? tuto.name[0..20] : tuto.titre[0..20]
      end
    end

    listing = VFCommand.new('list').output
    # puts "listing : #{listing}"
    alltutos.each do |item_listing|
      expect(listing).to include("#{item_listing}")
    end
    outtutos.each do |item_listing|
      expect(listing).not_to include("#{item_listing}")
    end
  end

  it 'avec l’option --name, affiche les noms des dossiers' do
    alltutos = []
    [
      VITEFAIT_CHANTIER_FOLDER,
      VITEFAIT_CHANTIERD_FOLDER,
      # VITEFAIT_COMPLETED_FOLDER,
      # VITEFAIT_PUBLISHED_FOLDER,
      VITEFAIT_ATTENTE_FOLDER
    ].each do |folder|
      alltutos += Dir["#{folder}/*"].collect do |p|
        tuto = ViteFait.new(File.basename(p))
        tuto.name[0..20]
      end
    end

    outtutos = []
    [
      VITEFAIT_COMPLETED_FOLDER,
      VITEFAIT_PUBLISHED_FOLDER
    ].each do |folder|
      outtutos += Dir["#{folder}/*"].collect do |p|
        tuto = ViteFait.new(File.basename(p))
        tuto.name[0..20]
      end
    end

    listing = VFCommand.new('list --name').output
    # puts "listing : #{listing}"
    alltutos.each do |item_listing|
      expect(listing).to include("#{item_listing}")
    end
    outtutos.each do |item_listing|
      expect(listing).not_to include("#{item_listing}")
    end
  end

  it 'avec l’option --all, affiche vraiment tous les tutoriels' do
    alltutos = []
    [
      VITEFAIT_CHANTIER_FOLDER,
      VITEFAIT_CHANTIERD_FOLDER,
      VITEFAIT_COMPLETED_FOLDER,
      VITEFAIT_PUBLISHED_FOLDER,
      VITEFAIT_ATTENTE_FOLDER
    ].each do |folder|
      alltutos += Dir["#{folder}/*"].collect do |p|
        tuto = ViteFait.new(File.basename(p))
        tuto.name[0..20]
      end
    end

    listing = VFCommand.new('list --all --name').output
    # puts "listing : #{listing}"
    alltutos.each do |item_listing|
      # puts "- Test de '#{item_listing}'"
      expect(listing).to include("#{item_listing}")
    end
  end
end
