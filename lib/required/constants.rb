
class ViteFait
  SHORT_SUJET_TO_REAL_SUJET = {
    'o'   => 'operations',
    's'   => 'scrivener',
    't'   => 'titre',
    'v'   => 'voice',
    'vi'  => 'vignette'
  }
end #/ViteFait

MIN_OPT_TO_REAL_OPT = {
  'e' => 'edit',
  'f' => 'force',
  'h' => 'help',
  'i' => 'infos',
  'l' => 'lack',
  'v' => 'verbose'
}

# Liste des clés de données fichiers (dans DATA_ALL_FILES) tels
# qu'ils sont créés par l'assistant dans l'ordre.
# Permet surtout de :
#   - faire un bilan avant d'assister une reprise de création
#   - pouvoir updater à partir d'un fichier en particulier
DATA_KEYS_FILES_OPERATION = [
  :informations,
  :titre_mov,
  :titre_mp4,
  :vignette_jpg,
  :operations,
  :capture_mov,
  :capture_mp4,
  :voice_mp4,
  :voice_aiff,
  :voice_aac,
  :titre_ts,
  :capture_ts,
  :final_tutoriel
]

DATA_ALL_FILES = {
  informations: {
    id:'informations',
    hname: "Fichier des informations générales",
    relpath: 'infos.json'
  },
  operations: {
    id: 'operations',
    hname: "Création du fichier des opérations et textes",
    relpath: 'Operations/operations.yaml',
    # Correspond à cette étape pour 'update from=...'
    from_update: 'operations'
  },

  # = CAPTURE OPÉRATIONS =
  capture_mov:{
    id: 'capture_mov',
    hname: "Capture brute des opérations",
    relpath: 'Operations/capture.mov',
    from_update: 'capture_operations'
  },
  capture_mp4: {
    id: 'capture_mp4',
    hname: "Assemblage des opérations et de la voix",
    relpath: 'Operations/capture.mp4',
    from_update: 'assemblage_capture_et_voix'
  },
  capture_ts:{
    id:'capture_ts',
    hname:"Vidéo finale pour assemblage (.ts)",
    relpath: 'Operations/capture.ts'
  },

  # = TITRE =
  titre_mov: {
    id: 'titre_mov',
    hname: "Capture brute du titre",
    relpath: 'Titre/Titre.mov',
    from_update: 'titre'
  },
  titre_mp4: {
    id: 'titre_mp4',
    hname: "Assemblage du titre",
    relpath: 'Titre/Titre.mp4'
  },
  titre_ts: {
    id: 'titre_mp4',
    hname: "Vidéo titre final pour assemblage (.ts)",
    relpath: 'Titre/Titre.ts'
  },

  # = VOIX =
  voice_mp4:{
    id: 'voice_mp4',
    hname: "Capture de la voix",
    relpath: 'Voix/voice.mp4',
    from_update: 'capture_voix'
  },
  voice_aiff:{
    id: 'voice_aiff',
    hname: "Capture de la voix modifié avec Audacity (ou autre)",
    relpath: 'Voix/voice.aiff'
  },
  voice_aac:{
    id: 'voice_aac',
    hname: "Fichier voix pour assemblage avec opérations (.aac)",
    relpath: 'Voix/voice.aac',
    from_update: 'improve_voice'
  },

  # = VIGNETTE =
  vignette_jpg:{
    id: 'vignette_jpg',
    hname: 'Vignette JPEG',
    relpath: 'Vignette/Vignette.jpg'
  },

  # = FICHIER TUTORIEL FINAL
  final_tutoriel:{
    id:'final_tutoriel',
    hname: "Fichier vidéo du tutoriel final (à uploader)",
    relpath: 'Exports/%{name}_completed.mp4',
    from_update: 'assemblage'
  }
}

def accelerator_for_speed speed
  ((1.0 / speed.to_f) * 100).to_i.to_f / 100
end
# Cette table permet d'utiliser plusieurs valeurs pour
# les même paramètres. Par exemple, pour le 'type' à
# la création, on peut mettre indifféremment 'attente',
# 'en_attente' ou 'waiting'
COMMAND_OTHER_PARAM_TO_REAL_PARAM = {
  'attente' => 'en_attente',
  'waiting' => 'en_attente'
}

COEF_DICTION = 0.07668

# Pour calculer le coefficiant de diction, on fait lire plusieurs
# textes à Audrey
def update_coefficiant_diction
  require_module('calcul_coefficiant_diction')
  calcul_coefficiant_diction
end

# Les valeurs par défaut pour les messages obtenus par MSG
# (cf. required/messages.rb et le manuel)
def MSG_default_variables
  {name:(vitefait && vitefait.name), titre:(vitefait && vitefait.titre), lieu:(vitefait && vitefait.lieu)}
end

# Données pour les types de version de tutoriel qu'on peut trouver
# TODO Mettre leurs dossier ici, pour pouvoir les modifier facilement et que
# ça se répercute partout ailleurs.
DATA_LIEUX = {
  chantier:   {folder_name:'2_En_chantier', place:'laptop', hname:"en chantier sur l'ordi"},
  completed:  {folder_name:'3_Completed',   place:'disk',   hname:"fini (sur le disque)"},
  chantierd:  {folder_name:'2_En_chantier', place:'disk',   hname:"en chantier, mais sur le disque"},
  attente:    {folder_name:'1_En_attente',  place:'disk',   hname:"en attente (sur le disque)"},
  published:  {folder_name:'4_Published',   place:'disk',   hname:"publié (sur le disque)"}
}

FOLDER_CAPTURES = File.join('/Volumes','MacOSCatalina','Captures')

BIN_FOLDER      = File.expand_path(File.dirname(THISFOLDER))
FOLDER_MODULES  = File.join(THISFOLDER,'modules')

VOICE_RECORDER_PATH = File.join(BIN_FOLDER,'lib','exe','voice_recorder.sh')

VITEFAIT_FOLDER_ON_LAPTOP = File.join(Dir.home,'Movies','Tutoriels','SCRIVENER','LES_VITE_FAITS')
VITEFAIT_FOLDER_ON_DISK   = File.join('/Volumes','MacOSCatalina','Screencasts','SCRIVENER','LES_VITE_FAITS')
VITEFAIT_MAIN_FOLDER = VITEFAIT_FOLDER_ON_DISK

DATA_LIEUX.each do |klieu, dlieu|
  eval("VITEFAIT_#{klieu.to_s.upcase}_FOLDER = File.join(VITEFAIT_FOLDER_ON_#{dlieu[:place].to_s.upcase}, dlieu[:folder_name])")
end

if File.exists?(VITEFAIT_FOLDER_ON_LAPTOP)
  unless File.exists?(VITEFAIT_CHANTIER_FOLDER)
    puts "ERROR : Le dossier '#{VITEFAIT_CHANTIER_FOLDER}' est introuvable…"
  end
else
  puts "ERROR : Le dossier '#{VITEFAIT_FOLDER_ON_LAPTOP}' est introuvable…"
end

unless File.exists?(VITEFAIT_FOLDER_ON_DISK)
  puts "ERROR : Le dossier '#{VITEFAIT_FOLDER_ON_DISK}' est introuvable…"
end

VITEFAIT_HELP_PATH    = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.md')
VITEFAIT_MANUAL_PATH  = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.pdf')

VITEFAIT_MATERIEL_FOLDER = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel')
