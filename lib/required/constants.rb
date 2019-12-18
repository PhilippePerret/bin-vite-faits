
MIN_OPT_TO_REAL_OPT = {
  'e' => 'edit',
  'f' => 'force',
  'h' => 'help',
  'i' => 'infos',
  'l' => 'lack',
  'v' => 'verbose'
}

# Données pour les types de version de tutoriel qu'on peut trouver
# TODO Mettre leurs dossier ici, pour pouvoir les modifier facilement et que
# ça se répercute partout ailleurs.
DATA_VERSION = {
  chantier:   {hname:"en chantier sur l'ordi"},
  complete:   {hname:"fini (sur le disque)"},
  chantierd:  {hname:"en chantier, mais sur le disque"},
  waiting:    {hname:"en attente (sur le disque)"}
}

FOLDER_MODULES = File.join(THISFOLDER,'modules')

VITEFAIT_FOLDER_ON_LAPTOP = File.join(Dir.home,'Movies','Tutoriels','SCRIVENER','LES_VITE_FAITS')
VITEFAIT_FOLDER_ON_DISK   = File.join('/Volumes','MacOSCatalina','Screencasts','SCRIVENER','LES_VITE_FAITS')
VITEFAIT_MAIN_FOLDER = VITEFAIT_FOLDER_ON_DISK

VITEFAIT_WORK_MAIN_FOLDER = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'2_En_chantier')

if File.exists?(VITEFAIT_FOLDER_ON_LAPTOP)
  unless File.exists?(VITEFAIT_WORK_MAIN_FOLDER)
    puts "ERROR : Le dossier '#{VITEFAIT_WORK_MAIN_FOLDER}' est introuvable…"
  end
else
  puts "ERROR : Le dossier '#{VITEFAIT_FOLDER_ON_LAPTOP}' est introuvable…"
end

unless File.exists?(VITEFAIT_FOLDER_ON_DISK)
  puts "ERROR : Le dossier '#{VITEFAIT_FOLDER_ON_DISK}' est introuvable…"
end

VITEFAIT_FOLDER_COMPLETED_ON_DISK = File.join(VITEFAIT_MAIN_FOLDER,'3_Completed')
VITEFAIT_FOLDER_WORKING_ON_DISK   = File.join(VITEFAIT_MAIN_FOLDER,'2_En_chantier')
VITEFAIT_FOLDER_PROJECT_ON_DISK   = File.join(VITEFAIT_MAIN_FOLDER,'1_En_projet')

VITEFAIT_HELP_PATH    = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.md')
VITEFAIT_MANUAL_PATH  = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.pdf')

VITEFAIT_MATERIEL_FOLDER = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel')
