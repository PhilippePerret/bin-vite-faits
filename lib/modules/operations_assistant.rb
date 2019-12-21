# encoding: UTF-8
=begin

  Ce module permet d'assistant à tout ce qui concerne les opérations
  À savoir :
    - la création du fichier opération lui-même
    - la lecture des opérations à exécuter
    - l'assistance de l'enregistrement de la voix

=end
class ViteFait
  def assistant_creation_file
    require_relative 'assistant/define_operations'
    exec
  rescue NotAnError => e
    e.puts_error_if_message
    return false
  end
end #/ViteFait
