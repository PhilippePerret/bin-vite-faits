# Pour la configuration
require_relative('../../config')

DEFAULT_BROWSER = CONFIG[:default_browser]

# Taille de la capture écran
# Faut-il le mettre dans config.rb ?
CAPTURE_WIDTH = 1680
CAPTURE_HEIGHT = 945

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
  'a' => 'assistant',
  'b' => 'backup',
  'e' => 'edit',
  'f' => 'force',
  'h' => 'help',
  'i' => 'infos',
  'l' => 'lack',
  't' => 'titre',
  'v' => 'verbose',
  'x' => 'test'
}

# Liste des clés de données fichiers (dans DATA_ALL_FILES) tels
# qu'ils sont créés par l'assistant dans l'ordre.
# Permet surtout de :
#   - faire un bilan avant d'assister une reprise de création
#   - pouvoir updater à partir d'un fichier en particulier
DATA_KEYS_FILES_OPERATION = [
  :informations,
  :titre_mov,
  :record_titre_mp4,
  :vignette_jpg,
  :operations,
  :capture_mov,
  :capture_mp4,
  :voice_mp4,
  # :voice_aiff,
  :record_voice_aac,
  :record_titre_ts,
  :capture_ts,
  :final_tutoriel,
  :upload,
  :annonce_fb,
  :annonce_scriv,
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
  record_titre_mp4: {
    id: 'record_titre_mp4',
    hname: "Assemblage du titre",
    relpath: 'Titre/Titre.mp4'
  },
  record_titre_ts: {
    id: 'record_titre_mp4',
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
  # voice_aiff:{
  #   id: 'voice_aiff',
  #   hname: "Capture de la voix modifié avec Audacity (ou autre)",
  #   relpath: 'Voix/voice.aiff'
  # },
  record_voice_aac:{
    id: 'record_voice_aac',
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
  },

  # = UPLOAD DE LA VIDÉO
  upload:{
    id:'upload',
    hname: "Upload de la vidéo finale",
    relpath: nil,
    information: 'uploaded'
  },

  # = ANNONCES
  annonce_fb:{
    id:'annonce_fb',
    hname: "Annonce sur le groupe Facebook",
    relpath: nil,
    information: 'annonce_fb',
    from_update: 'annonces'
  },

  annonce_scriv:{
    id: 'annonce_scriv',
    hname: "Annonce sur le forum Scrivener",
    relpath: nil,
    information: 'annonce_scriv',
    from_update: 'annonces'
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
  require_module('voice/calcul_coefficiant_diction')
  calcul_coefficiant_diction
end

# Les valeurs par défaut pour les messages obtenus par MSG
# (cf. required/messages.rb et le manuel)
def MSG_default_variables
  {name:(vitefait.defined? && vitefait.name), titre:(vitefait.exists? && vitefait.titre), lieu:(vitefait.exists? && vitefait.lieu)}
end

# Données pour les types de version de tutoriel qu'on peut trouver
# Mettre leurs dossier ici, pour pouvoir les modifier facilement et que
# ça se répercute partout ailleurs.
DATA_LIEUX = {
  chantier:   {id: :chantier,   folder_name:'2_En_chantier', place:'laptop', hname:"en chantier sur l'ordi", short_hname:'ordi›chantier'},
  chantierd:  {id: :chantierd,  folder_name:'2_En_chantier', place:'disk',   hname:"en chantier, mais sur le disque", short_hname:'disk›chantier'},
  attente:    {id: :attente,    folder_name:'1_En_attente',  place:'disk',   hname:"en attente (sur le disque)", short_hname:'disk›attente'},
  completed:  {id: :completed,  folder_name:'3_Completed',   place:'disk',   hname:"fini (sur le disque)", short_hname:'disk›fini'},
  published:  {id: :published,  folder_name:'4_Published',   place:'disk',   hname:"publié (sur le disque)", short_hname:'disk›publié'},
}

FOLDER_CAPTURES             = CONFIG[:captures_folder]
VITEFAIT_FOLDER_ON_LAPTOP   = CONFIG[:laptop_folder]
VITEFAIT_FOLDER_ON_DISK     = CONFIG[:disk_folder]
VITEFAIT_MAIN_FOLDER        = VITEFAIT_FOLDER_ON_DISK
VITEFAIT_BACKUP_FOLDER      = CONFIG[:backup_folder]


BIN_FOLDER      = File.expand_path(File.dirname(THISFOLDER))
FOLDER_MODULES  = File.join(THISFOLDER,'modules')

VOICE_RECORDER_PATH = File.join(BIN_FOLDER,'lib','exe','voice_recorder.sh')

# Pour obtenir facilement un dossier avec VITEFAIT_FOLDERS[<key>]
# Par exemple VITEFAIT_FOLDERS[:chantierd] retourne le path au
# dossier chantier sur le disque. tandis que VITEFAIT_FOLDERS[:backup]
# retourne le dossier backup sur l'autre disque.
# Noter qu'une boucle sur tous les items permet de fouiller tous les
# endroits où on peut trouver des tutoriels vite-faits.
VITEFAIT_FOLDERS = {
  backup: VITEFAIT_BACKUP_FOLDER
}
DATA_LIEUX.each do |klieu, dlieu|
  eval(
  <<-EOC
VITEFAIT_#{klieu.to_s.upcase}_FOLDER = File.join(VITEFAIT_FOLDER_ON_#{dlieu[:place].to_s.upcase}, dlieu[:folder_name])
VITEFAIT_FOLDERS.merge!(:#{klieu} => VITEFAIT_#{klieu.to_s.upcase}_FOLDER)
  EOC
)
end

VITEFAIT_MARKDOWN_MANUAL_PATH    = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.md')
VITEFAIT_PDF_MANUAL_PATH  = File.join(VITEFAIT_FOLDER_ON_DISK,'Manuel-les-vite-faits.pdf')
VITEFAIT_PDF_MANUAL_PATH_ON_LAPTOP = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Manuel-les-vite-faits.pdf')
VITEFAIT_HTML_MANUAL_URI = File.join('LesViteFaits','Manuel-les-vite-faits.html')
VITEFAIT_HTML_MANUAL_PATH = File.join(Dir.home,'Sites','LesViteFaits','Manuel-les-vite-faits.html')

VITEFAIT_MATERIEL_FOLDER = File.join(VITEFAIT_FOLDER_ON_LAPTOP,'Materiel')
