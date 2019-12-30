# encoding: UTF-8
=begin

  Module pour l'assistance de l'enregistrement du titre

=end
def exec(options = nil)

  if titre_recorded?
    if yesNo("L'enregistrement du titre existe déjà. Dois-je le refaire ?")
      unlink_if_exist([titre_mov, record_titre_mp4, record_titre_ts])
    else
      return
    end
  end

  clear
  notice "= Enregistrement du TITRE ANIMÉ ="
  puts <<-EOT

Je vais t'assister dans la réalisation de la
capture du titre.

  A   Me rappeler toutes les opérations de
      préparation à faire.

  B   Commencer tout de suite.

  Q   Quitter l'assistant.

  EOT

  oldquiet = COMMAND.options[:quiet]
  COMMAND.options[:quiet] = true
  open_something('titre') || return
  activate_terminal

  choix = nil
  while choix.nil?
    choix = (getChar("Quel est ton choix ?")||'').upcase
    case choix
    when 'Q'
      raise NotAnError.new
    when 'A' # avec assistant
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
    when 'B'
      `open -a Scrivener`
    else
      error "Je ne connais pas ce choix"
      choix = nil
    end
  end

  yesOrStop("Tape 'y' ou 'o' lorsque tu auras fini.")
  ViteFait.move_last_capture_in(record_titre_mov) || raise(NotAError.new("Tu n'as pas enregistré le titre. je dois renoncer."))

  if IO.check_existence(titre_mov, {thing: "capture du titre", success: "la capture du titre a bien été exécutée", failure: "La capture du titre a échoué…"})
    save_last_logic_step
  end
end
