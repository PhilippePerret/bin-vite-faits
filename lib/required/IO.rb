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

  # Copie le fichier +src+ vers le ficheir +dst+ en s'assurant que
  # l'opération s'est bien passée
  def copy_with_care(src,dst,what = nil, interactive = true)
    (src && src != '')  || raise(ArgumentError.new("Le chemin d'accès au fichier source doit impérativement être défini."))
    File.exists?(src)   || raise(ArgumentError.new("Impossible de trouver le fichier source (*)… Je dois renoncer.\n(*) #{src}"))
    (dst && dst != '')  || raise(ArgumentError.new("Le chemin d'accès au fichier destination doit impérativement être défini."))
    what ||= (File.directory?(src) ? 'dossier' : 'fichier')
    # Il faut détruire le fichier destination s'il existe
    remove_with_care(dst,"#{what} destination",interactive,force=true) || return
    # On fait la copy
    FileUtils.copy(src,dst)

    if File.exists?(dst)
      notice "👍  Le #{what} source a été dupliqué." if interactive
    else
      error "🚫  Le #{what} source (*) n'a pas pu être dupliqué…\n(*) #{path}"
      return false
    end

    # On vérifie l'intégrité du fichier
    if Digest::SHA2.file(src).hexdigest == Digest::SHA2.file(dst).hexdigest
      notice "👍  Les deux fichiers sont identiques." if interactive
    else
      error "🚫  Les deux fichiers sont différents (checksum)… La copie n'est pas correcte."
      return false
    end
    return true # tout s'est bien passé
  end

  # Détruit un élément en s'assurant qu'il existe et qu'il n'existe plus
  # à la fin.
  #
  # Note : l'élément n'est pas vraiment détruit, il est placé dans le
  # dossier trash du tutoriel.
  #
  # Retourne TRUE en cas de succès, false dans le cas contraire.
  # Params:
  #   +path+::  [String] Le chemin d'accès à l'élément à détruire
  #   +thing+:: [String] La désignation humaine de l'élément à détruire.
  #   +interactive+:: [Boolean] Si true, on affiche les messages. Sinon,
  #             l'opération reste silencieuse.
  #   +force+:: [Boolean] Si true, on ne vérifie pas que le fichier se trouve
  #             dans le dossier de l'utilisateur courant. À utiliser seulement
  #             si on est sûr.
  def remove_with_care(path, thing = nil, interactive = true, force = false)
    (path && path != '') || raise(ArgumentError.new("Le chemin d'accès doit impérativement être défini."))
    (path.start_with?('/') && (path.start_with?(Dir.home) || force)) || raise(ArgumentError.new("Par mesure de prudence, il est interdit de détruire un élément hors du “home” de l'utilisateur."))
    thing ||= (File.directory?(src) ? 'dossier' : 'fichier')
    if File.exists?(path)
      if File.directory?(path)
        FileUtils.rm_rf(path)
      else
        ViteFait.remove(path)
        # FileUtils.remove(path) # pour une autre application
      end
      if File.exists?(path)
        error "🚫  Le #{thing} (*) n'a pas pu être détruit…\n(*) #{path}"
        return false
      else
        notice "👍  Le #{thing} a été détruit." if interactive
        return true
      end
    else
      # Si le fichier n'existe pas, il n'y a rien à faire
      # TODO il faudrait un moyen, quand même, de préciser qu'il faut
      # faire une alerte dans certaines situation.
      return true
    end
  rescue Exception => e
    error e.message
    error "Je ne procède pas à la destruction de '#{path}'."
  end #/remove_with_case


  # +return+ [Boolean] True en cas d'existence, false en cas d'absence
  def check_existence path, params = nil
    params ||= {}
    params[:thing]    ||= "dosier/fichier “#{path && File.basename(path)}”"
    params[:success]  ||= "le #{params[:thing]} existe bien."
    params[:failure]  ||= "le #{params[:thing]} est introuvable…"
    params[:interactive].nil? && params[:interactive] = true
    if path && File.exists?(path)
      if params[:interactive]
        notice "---> #{params[:success]} 👍"
      end
      return true
    else
      error "🚫  #{params[:failure]}"
      return false
    end
  end
end #/<< self
end #/IO
