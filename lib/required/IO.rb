# encoding: UTF-8
=begin

  Module pratique de gestion des Files/dossiers.

  Requis
  ------
    * Une méthode 'error' qui reçoit un message d'erreur ({String})
      et retourne false
    * Une méthode 'notice' qui reçoit un message de confirmation ({String})
      et l'écrit (en vert par exemple) en console.

=end

class IO
class << self

  # Détruit un élément en s'assurant qu'il existe et qu'il n'existe plus
  # à la fin.
  # Retourne TRUE en cas de succès, false dans le cas contraire.
  # @param {String} path
  # Params:
  #   +path+:: [String] Le chemin d'accès à l'élément à détruire
  def remove_with_care(path, thing = nil, interactive = true)
    (path && path != '') || raise(ArgumentError.new("Le chemin d'accès doit impérativement être défini."))
    (path.start_with?('/') && path.start_with?(Dir.home)) || raise(ArgumentError.new("Par mesure de prudence, il est interdit de détruire un élément hors du “home” de l'utilisateur."))
    thing ||= "dossier/fichier"
    if File.exists?(path)
      if File.directory?(path)
        FileUtils.rm_rf(path)
      else
        FileUtils.remove(path)
      end
      if File.exists?(path)
        error "🚫  Le #{thing} (*) n'a pas pu être détruit…\n(*) #{path}"
        return false
      else
        notice "👍  Le #{thing} a été détruit." if interactive
        return true
      end
    else
      error "🚫  Impossible de trouver le #{thing} (*) à détruire…\n(*) #{path}"
      return false
    end
  rescue Exception => e
    error e.message
    error "Je ne procède pas à la destruction demandée."
  end #/remove_with_case
end #/<< self
end #/IO
