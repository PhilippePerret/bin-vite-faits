
MIN_OPT_TO_REAL_OPT = {
  'e' => 'edit',
  'f' => 'force',
  'h' => 'help',
  'i' => 'infos',
  'l' => 'lack',
  'v' => 'verbose'
}

# Cette table permet d'utiliser plusieurs valeurs pour
# les même paramètres. Par exemple, pour le 'type' à
# la création, on peut mettre indifféremment 'attente',
# 'en_attente' ou 'waiting'
COMMAND_OTHER_PARAM_TO_REAL_PARAM = {
  'attente' => 'en_attente',
  'waiting' => 'en_attente'
}

# Les valeurs par défaut pour les messages obtenus par MSG
# (cf. required/messages.rb et le manuel)
def MSG_default_variables
  {name:(vitefait && vitefait.name), titre:(vitefait && vitefait.titre), lieu:(vitefait && vitefait.lieu)}
end

# Données pour les types de version de tutoriel qu'on peut trouver
# TODO Mettre leurs dossier ici, pour pouvoir les modifier facilement et que
# ça se répercute partout ailleurs.
DATA_LIEUX = {
  chantier:   {hname:"en chantier sur l'ordi"},
  completed:  {hname:"fini (sur le disque)"},
  chantierd:  {hname:"en chantier, mais sur le disque"},
  attente:    {hname:"en attente (sur le disque)"},
  published:  {hname:"publié (sur le disque)"}
}

FOLDER_CAPTURES = File.join('/Volumes','MacOSCatalina','Captures')

BIN_FOLDER      = File.expand_path(File.dirname(THISFOLDER))
FOLDER_MODULES  = File.join(THISFOLDER,'modules')

VOICE_RECORDER_PATH = File.join(BIN_FOLDER,'voice_recorder.sh')

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

VITEFAIT_PUBLISHED_FOLDER_ON_DISK = File.join(VITEFAIT_MAIN_FOLDER,'4_Published')
VITEFAIT_FOLDER_COMPLETED_ON_DISK = File.join(VITEFAIT_MAIN_FOLDER,'3_Completed')
VITEFAIT_FOLDER_WORKING_ON_DISK   = File.join(VITEFAIT_MAIN_FOLDER,'2_En_chantier')
VITEFAIT_FOLDER_PROJECT_ON_DISK   = File.join(VITEFAIT_MAIN_FOLDER,'1_En_projet')

VITEFAIT_HELP_PATH    = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.md')
VITEFAIT_MANUAL_PATH  = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.pdf')

VITEFAIT_MATERIEL_FOLDER = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel')
