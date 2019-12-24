# encoding: UTF-8
=begin
  Module d'assistance à la définition des opérations
  à exécuter dans le tutoriel.
=end

# Assistant pour la création du fichier opérations
# Cette méthode doit être appelée entre des :
#   begin
#     exec
#   rescue NotAnError => e
#     e.puts_error_if_message
#   end
def exec(options=nil)

  clear

  operations = nil

  # Si un fichier des opérations existe déjà, il faut demander ce qu'il
  # faut faire avec, le refaire, le poursuivre ou continuer sans rien
  # toucher.
  if operations_are_defined?
    notice "=== Définitions des opérations ==="
    demande = <<-EOD

  Le fichier des opérations existe. Que dois-je faire ?

    A: le détruire pour recommencer,
    B: le poursuivre avec cet assistant,
    C: l'éditer avec Vim
    D: ne rien changer.

>>>
    EOD
    case getChar(demande).downcase
    when 'a'
      # Détruire le fichier
      File.unlink(operations_path)
    when 'b'
      # Poursuivre le fichier
      operations = get_operations
    when 'c'
      # Éditer le fichier avec Vim
      puts texte_ouverture_dans_Vim
      open_operations_file
      return yesNo("Tape 'y' pour poursuivre.")
    when 'd'
      return true
    else
      error "Je ne comprends pas ce choix. Je ne fais rien."
      return
    end
  else
    # <= Le fichier opérations n'est pas encore créé
    # => on affiche un texte informatif.
    clear
    notice "=== Définition des opérations ==="
    puts <<-EOT

Nous allons définir les opérations à exécuter dans ce
tutoriel. Cela consiste à définir :

  id:           Un identifiant unique de l'opération,
  assistant:    L'opération à exécuter, qui sera dite
                par l'assistant lors de la création as-
                sistée. Ce texte doit décrire ce qu'il
                faut faire précisément.
  voice:        Le texte que je devrais dire sur les
                opérations exécutées pour expliquer au
                spectateur de la vidéo ce qui doit être
                fait.
  duration:     La durée optionnelle de l'opération, si
                les textes sont trop courts par exemple.
                Si cette valeur n'est pas définie expli-
                citement, elle sera calculée d'après la
                longueur du plus grand texte (entre l'as-
                sitant et la 'voice'). Ce qui fait que
                cette durée peut coller presque parfaite-
                ment au texte qui sera dit dans le tuto-
                riel.

    EOT

  end

  operations = get_all_operations_voulues(operations)

  puts "Fichier qui va être produit :"
  puts YAML.dump(operations)

  yesNo("\nDois-je procéder à la fabrication du fichier ?") || return

  # Créer le dossier s'il n'existe pas
  `mkdir -p "#{operations_folder}"`

  File.open(operations_path,'wb'){|f| f.write YAML.dump(operations)}

  if operations_are_defined?
    notice "Fichier des opérations enregistré avec succès. 👍"
    puts <<-EOT
  Tu peux jouer la commande suivante pour que l'assistant
  te lise les opérations à exécuter :
      vite-faits assistant #{name} pour=capture
  Tu peux jouer la commande suivante pour afficher le texte à dire par la voix finale :
      vite-faits assistant #{name} pour=voice

    EOT
  else
    # Le fichier n'a pas été enregistré
    error "🚫  Bizarrement, je ne trouve pas le fichier des opérations…"
  end
end #/exec

def get_all_operations_voulues(operations = nil)
  operations ||= []
  operations_ids = {}
  operations.each { |op| operations_ids.merge!( op[:id] => true ) }

  while true
    # identifiant de l'opération
    begin
      operation_id = prompt("\nID nouvelle opération (rien pour interrompre)")
      if operation_id.nil? || operation_id == 'q'
        return operations
      end
    end while operation_id_invalid?(operation_id, operations_ids)
    raise NotAnError.new() if operation_id == 'q'

    # Manipulation à opérer
    begin
      operation_assistant = prompt("Message à DIRE par l'assistant")
    end while operation_assistant.nil?
    raise NotAnError.new() if operation_assistant == 'q'

    # Texte de la voix finale
    begin
      operation_voice = prompt("TEXTE de la voix finale du tutoriel")
    end while operation_voice.nil?
    raise NotAnError.new() if operation_voice == 'q'

    operation_duration = prompt("DURÉE forcée en seconde")
    raise NotAnError.new() if operation_duration == 'q'
    operation_duration.nil? || operation_duration = operation_duration.to_i

    operations << {
      id:         operation_id,
      assistant:  operation_assistant,
      voice:      operation_voice,
      duration:   operation_duration
    }

    # Pour checker l'unicité des identifiants d'opération
    operations_ids.merge!(operation_id => true)
  end
end

# Retourne true si l'identifiant d'opération +op_id+ est valide
def operation_id_invalid?(op_id, operations_ids)
  op_id.nil? && raise("Il faut définir l'identifiant unique de l'opération.")
  operations_ids.key?(op_id) && raise("Cet identifiant est déjà utilisé par une opération.")
  return false
rescue Exception => e
  error(e.message)
  error("Mettre l'id à 'q' pour renoncer.")
  return true
end

def texte_ouverture_dans_Vim
  <<-EOT
Je vais ouvrir le fichier dans Vim pour le mettre
en édition. Modifie-le à ta guise, puis enregistre-
le et quitte l'édition avec `:wq` et reviens ici
pour poursuivre.
  EOT
end
