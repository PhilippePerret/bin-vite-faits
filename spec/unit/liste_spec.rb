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
  it 'contient bien tous les tutoriels' do
    # On va récupérer les tutoriels dans les différents dossiers
    alltutos = []
    [
      VITEFAIT_CHANTIER_FOLDER,
      VITEFAIT_CHANTIERD_FOLDER,
      VITEFAIT_COMPLETED_FOLDER,
      VITEFAIT_ATTENTE_FOLDER,
      VITEFAIT_PUBLISHED_FOLDER
    ].each do |folder|
      alltutos += Dir["#{folder}/*"].collect{|p|File.basename(p)}
    end

    listing = VFCommand.new('list').output
    puts "listing : #{listing}"
    alltutos.each do |tuto_name|
      # STDOUT.write "\n#{tuto_name} ?"
      expect(listing).to include("#{tuto_name}")
      # STDOUT.write " OK"
    end
  end
end
