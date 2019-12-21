# encoding: UTF-8
=begin

  Module pour l'assistance de l'enregistrement du titre

=end
def exec(options = nil)
  clear
  notice "= Enregistrement du TITRE ANIMÉ ="
  puts <<-EOT
Je vais ouvrir le modèle, il te suffira alors de :

- régler la largeur de fenêtre et de faire un essai,
- régler l'enregistrement (Cmd+Maj+5) :
  • Minuteur   : 5 secondes
  • Microphone : aucun, sans son,
  • Tout l'écran,
- lancer l'enregistrement,
- arrêter la capture assez vite (la dernière seconde
  sera coupée),
- et revenir ici.

Titre à écrire dans le document :

    « #{titre} ».

EOT
  yesOrStop("Clique 'y' pour que j'ouvre le titre modèle.")
  open_titre(nomessage = true)
  # Ouvrir aussi le dossier des captures et le dossier du tutoriel
  ViteFait.open_folder_captures
  open_in_finder(:chantier)
  `open -a Terminal`

  yesOrStop("Tape 'y' lorsque tu auras fini.")
  ViteFait.move_last_capture_in(default_titre_file_path) || raise(NotAError.new("Tu n'as pas enregistré le titre. je dois renoncer."))

end
