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
  # Le fichier des opérations est requis

  avec_assistant_operations = file_operations_exists?

  clear
  notice "=== Enregistrement de la voix finale ==="
  puts <<-EOT

Je vais t'accompagner au cours de toutes les
opérations à exécuter.

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
    dire("Active la capture et règle la sur : tout l'écran, Minuteur : aucun, Microphone : microphone intégré")
    sleep 4
    dire("Démarrage dans 10 secondes")
    decompte("Démarrage dans %{nombre_secondes}", 3)
    dire("Démarrage dans 5 secondes")
    decompte("Démarrage dans %{nombre_secondes}", 4, 'Audrey')
    dire("C'est parti ! Mets en route la capture !")

    if avec_assistant_operations
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
      dire "Lorsque tu auras fini, arrête la capture et reviens dans le Terminal."
    end

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

  return yesNo("Tape 'y'.")
end
