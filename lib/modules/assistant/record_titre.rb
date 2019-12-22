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

Je vais t'assister dans la réalisation de la
capture du titre.

  EOT

  open_titre(nomessage = true) || return
  `open -a Terminal`
  yesOrStop("Es-tu prêt ?")

  direEtFaire([
    {exec: "`open -a Scrivener`"},
    "Dans Scrivener, masque les autres applications (Command, Alte, H)",
    "Assure-toi qu'on ne voie rien dans le Finder",
    "Écrit le titre : “#{titre}“…",
    "Règle la largeur de la fenêtre pour que le titre apparaisse bien…",
    "Supprime le titre",
    "Active la capture (Commande, Majuscule, 5) et règle ses options avec : Écran complet",
    "Minuteur : 5 secondes, Microphone : aucun",
    "Il faudra arrêter l'enregistrement assez rapidement (la dernière seconde sera supprimée)",
    "À la fin, il faudra enregistrer le fichier et le fermer",
    "Lance la capture et tape le titre : “#{titre}”"
    ])


  yesOrStop("Tape 'y' — pour 'yes' — lorsque tu auras fini.")
  ViteFait.move_last_capture_in(default_titre_file_path) || raise(NotAError.new("Tu n'as pas enregistré le titre. je dois renoncer."))

  IO.check_existence(titre_mov, {thing: "capture du titre", success: "la capture du titre a bien été exécutée", failure: "La capture du titre a échoué…"})
end
