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

  # Ouvrir toujours le projet Scrivener (en réalité : une copie du
  # projet préparé)
  open_something('scrivener') || raise(NotAnError.new)

  clear
  `open -a Terminal`
  notice "=== Enregistrement des opérations ==="

  # Si un fichier capture.mov existe déjà, on demande à l'utilisateur
  # si on doit le détruire pour le recommencer
  if operations_recorded?
    ask_for_new_version_or_destroy_record_operations
  end

  # Pour savoir si on doit enregistrer avec l'assistant des
  # opérations ou sans.
  avec_assistant_operations = operations_defined?


  puts <<-EOT

Je vais t'accompagner au cours des opérations
à exécuter.


À tout moment, si ça ne se passe pas bien, tu
peux interrompre la capture à l'aide de CTRL-C.

  EOT

  if avec_assistant_operations
    puts <<-EOT
  Les opérations du tutoriel étant définies, je vais
  pouvoir t'accompagner dans le détail.

    EOT
  else
    puts <<-EOT
  S'il y avait un fichier définissant les opérations,
  je pourrais t'accompagner beaucoup mieux."

    EOT
  end

  yesOrStop("Prêt à commencer ?…")

  is_first_time = true

  begin #Boucle jusqu'à ce qu'on arrive à une vidéo acceptable

    dire("Active Scrivener et masque les autres applications avec Commande, ALTE, H")
    sleep 3 if is_first_time
    dire("Active la capture et règle-la avec les valeurs : tout l'écran, Minuteur : aucun, Microphone : microphone intégré")

    if avec_assistant_operations
      if is_first_time
        dire("Démarrage dans 10 secondes")
        sleep 4
        decompte("Démarrage dans %{nombre_secondes}", 3)
      end
      dire("Démarrage dans 5 secondes")
      decompte("Démarrage dans %{nombre_secondes}", 4, 'Audrey')
      dire("Mets en route la capture !")

      # Boucle sur toutes les opérations
      # --------------------------------

      operations.each do |operation|
        op_start_time = Time.now.to_i
        # Calcul du temps de fin
        end_sleep_time = op_start_time + operation.duree_estimee
        `say -v Thomas -r 140 "#{operation.formated_assistant}"`
        sleep_reste = end_sleep_time - Time.now.to_i
        sleep_reste < 0 && sleep_reste = 0
        sleep sleep_reste
      end #/boucle sur toutes les opérations

      # À la fin, on laisse encore 3 secondes pour finir
      sleep 3
      dire "Arrête maintenant la capture (les deux dernières secondes seront supprimées). Puis reviens dans le Terminal."
    else
      # Sans assistant opérations, on attend la fin
      dire "Tu peux lancer la capture quand tu veux."
      dire "Lorsque tu auras fini, arrête la capture et reviens dans le Terminal."
    end

    is_first_time = false # si on remonte, on n'attendra moins
  end while !yesNo("Cette capture est-elle bonne ? (tape 'n' pour la recommencer)")


  # On va prendre la dernière capture effectuée pour la mettre en
  # fichier capture
  ViteFait.move_last_capture_in(default_record_operations_path)

  if operations_recorded?
    require_module('duree')

    notice <<-EOT

Opérations enregistrées avec succès ! 👍

Durée capturée : #{operations_duration.as_horloge}
Durée tutoriel : #{tutoriel_duration.as_horloge}

Tu peux enregistrer la voix finale avec :
    vite-faits assistant #{name} pour=voice
Tu peux demander l'assemblage avec :
    vite-faits assemble #{name}

Tu peux lire le contenu des opérations avec :
    vite-faits operations [#{name}]
Tu peux modifier ce document, dans Vim, avec :
    vite-faits operations [#{name}] -e/--edit

    EOT
    save_last_logic_step
  else
    # Le fichier .mov de la capture n'a pas été produit…
    raise NotAnError.new("Sans fichier capture.mov, je ne peux pas poursuivre…")
  end

  yesOrStop("Tape 'y' pour poursuivre.")
end

# Méthode appelée quand il existe déjà un enregistrement des opérations,
# pour savoir s'il faut faire une nouvelle version ou détruire le fichier
def ask_for_new_version_or_destroy_record_operations
  puts <<-EOT

Une capture des opérations existe déjà. Que dois-je
faire ?

  A Faire une nouvelle version (en mettant l'ancienne
    de côté),

  B Détruire la version existante pour la refaire
    complètement.

  EOT
  while true
    case (getChar("Ton choix :")||'').upcase
    when 'A'
      make_new_version_record_operations
      break
    when 'B'
      if yesNo("Confirmes-tu la DESTRUCTION DÉFINITIVE de l'enregistrement ?")
        IO.remove_with_care(record_operations_path,'record des opérations',false)
        IO.remove_with_care(record_operations_mp4, 'record des opérations (.mp4)',false)
        IO.remove_with_care(record_operations_ts,'record des opérations (.ts)',false)
        break
      end
    when 'Q'
      raise NotAnError.new()
    else
      error("Je ne connais pas ce choix")
    end
  end #/fin de boucle en attendant un choix valide
end #/ask_for_new_version_or_destroy_record_operations

# Méthode pour produire une nouvelle version du fichier
def make_new_version_record_operations
  iversion = 0
  path_version = nil
  while path_version.nil?
    iversion += 1
    path_version = pathof(File.join('Operations',"capture-v#{iversion}.mp4"))
    path_version = nil if File.exists?(path_version)
  end
  # Il faut faire le fichier mp4 s'il n'existe pas
  # (noter qu'ici le fichier .mov existe forcément)
  File.exists?(record_operations_mp4) || capture_to_mp4
  # On peut créer la nouvelle version
  FileUtils.move(record_operations_mp4, path_version)
  notice "Version Operations/capture_v#{iversion}.mp4 produite 👍"
  IO.remove_with_care(record_operations_ts,'record des opérations',false)

  if File.exists?(record_operations_mp4)
    raise NotAnError.new("Le fichier original (*) ne devrait pas exister…\n(*) #{record_operations_mp4}")
  end
  unless File.exists?(path_version)
    raise NotAnError.new("Le fichier version (*) devrait exister…\n(*) #{path_version}")
  end
  return true
end
