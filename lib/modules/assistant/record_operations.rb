# encoding: UTF-8
=begin

  Module d'assistance à la création de la vidéo des
  opérations du tutoriel.

=end


# Assistant pour la réalisation des opérations, en les lisant
# Note : pour l'utiliser ailleurs que dans l'assistant général,
# il faut l'entourer d'un rescue :
#   begin
#     require_module('assistant/record_operations')
#     exec
#   rescue NotAnError => e
#     e.puts_error_if_message
#   end
#
# Note : les +options+ ne servent à rien, pour le moment.
#
def exec(options=nil)

#   # pour essayer de façon automatique
# Mais je n'y arrive ni avec AppleScript (problème de permission),
# ni avec screencapture ou ffmpg (problème d'arrêt — je ne sais pas
# comment les arrêter)
#   `osascript <<EOT
# tell app "QuickTime Player"
#   new screen recording
#   start document 1
#   delay 5
#   stop document 1
#   export document 1 in "#{default_source_path}" using settings preset "480p"
#   close document 1
#   quit
# end tell
#   EOT`
#   return

  # Ouvrir toujours le projet Scrivener
  open_scrivener_project || raise(NotAnError.new)

  clear
  `open -a Terminal`
  notice "=== Enregistrement des opérations ==="

  # Si un fichier capture.mov existe déjà, on demande à l'utilisateur
  # si on doit le détruire pour le recommencer
  if operations_are_recorded?
    error "\n[NON FATAL] Un enregistrement des opérations existe déjà."
    choix_final = false
    if yesNo("Dois-je le détruire pour recommencer ?")
      choix_final = yesNo("Confirmes-tu la DESTRUCTION DÉFINITIVE de l'enregistrement ?")
    end
    choix_final || return
    File.unlink(src_path)

  end

  # Pour savoir si on doit enregistrer avec l'assistant des
  # opérations ou sans.
  avec_assistant_operations = operations_are_defined?

  ajout_assistant_operations =
  if avec_assistant_operations
    "Grâce aux fichiers définissant ces\nopérations, je vais pouvoir t'accompagner dans\nle détail."
  else
    "S'il y avait un fichier définissant\nles opérations, je pourrais t'accompagner beau-\ncoup mieux."
  end


  puts <<-EOT

Je vais t'accompagner au cours des opérations
à exécuter. #{ajout_assistant_operations}


À tout moment, si ça ne se passe pas bien, tu
peux interrompre la capture à l'aide de CTRL-C.

  EOT

  if avec_assistant_operations
    puts <<-EOT
  Les opérations du tutoriel étant définies, je vais
  pouvoir t'accompagner dans le détail.

    EOT
  end

  yesOrStop("Prêt à commencer ?…")

  begin #Boucle jusqu'à ce qu'on arrive à une vidéo acceptable

    dire("Active Scrivener et masque les autres applications avec Commande + Alte + H")
    sleep 3
    dire("Active la capture et règle-la avec les valeurs : tout l'écran, Minuteur : aucun, Microphone : microphone intégré")

    if avec_assistant_operations
      sleep 4
      dire("Démarrage dans 10 secondes")
      decompte("Démarrage dans %{nombre_secondes}", 3)
      dire("Démarrage dans 5 secondes")
      decompte("Démarrage dans %{nombre_secondes}", 4, 'Audrey')
      dire("C'est parti ! Mets en route la capture !")
      get_operations.each do |operation|
        if operation[:duration]
          end_sleep_time = Time.now.to_i + operation[:duration]
        end
        `say -v Thomas -r 140 "#{operation[:assistant]}"`
        if operation[:duration]
          sleep_reste = end_sleep_time - Time.now.to_i
          sleep_reste < 0 && sleep_reste = 0
        else
          sleep_reste = 1
        end
        sleep sleep_reste
      end #/boucle sur toutes les opérations
      # À la fin, on laisse encore 3 secondes pour finir
      sleep 3
      dire "Arrête maintenant la capture. Et reviens dans le Terminal."
    else
      # Sans assistant opérations, on attend la fin
      dire "Tu peux lancer la capture quand tu veux."
      dire "Lorsque tu auras fini, arrête la capture et reviens dans le Terminal."
    end
    dire "Pour information, les deux dernières secondes seront supprimées."

  end while !yesNo("Cette capture est-elle bonne ? (tape 'n' pour la recommencer)")

  # On va prendre la dernière capture effectuée pour la mettre en
  # fichier capture
  ViteFait.move_last_capture_in(default_source_path)

  if operations_are_recorded?

    notice <<-EOT

Opérations enregistrées avec succès ! 👍

Tu peux enregistrer la voix finale avec :
    vite-faits assistant #{name} pour=voice
Tu peux demander l'assemblage avec :
    vite-faits assemble #{name}

    EOT
  else
    # Le fichier .mov de la capture n'a pas été produit…
    raise NotAnError.new("Sans fichier capture.mov, je ne peux pas poursuivre…")
  end

  yesOrStop("Tape 'y' pour poursuivre.")
end
