# encoding: UTF-8
=begin

  Module pour l'assistance de l'enregistrement du titre

=end
def exec(options = nil)

  if record_titre_exists?
    if yesNo("L'enregistrement du titre existe déjà. Dois-je le refaire ?")
      unlink_if_exist([titre_mov, titre_mp4, titre_ts])
    else
      return
    end
  end

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

  yesOrStop("Tape 'y' — pour 'yes' — lorsque tu auras fini.")
  ViteFait.move_last_capture_in(default_titre_file_path) || raise(NotAError.new("Tu n'as pas enregistré le titre. je dois renoncer."))

  if titre_mov && File.exists?(titre_mov)
    notice "---> Enregistrement titre effectué avec succès 👍"
  else
    error "Le titre n'a pas pu être enregistré."
  end
end
