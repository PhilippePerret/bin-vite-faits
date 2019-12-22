# encoding: UTF-8
=begin

  Module gérant le projet scrivener du tutoriel

=end
class ViteFait
  class ScrivenerProject

    attr_reader :vitefait
    def initialize vitefait
      @vitefait = vitefait
    end

    def open
      vitefait.project_scrivener_exists?(required=true) || return
      if COMMAND.options[:edit]
        open_project_prepared
      else
        if ask_for_prepared_or_copie
          open_project_prepared
        else
          duplique_and_open # Il faut ouvrir une copie
        end
      end
    rescue NotAnError => e
      e.puts_error_if_message
      error "Abandon de l'ouverture."
    end #/open

    def ask_for_prepared_or_copie
      clear
      notice "=== Ouverture du projet Scrivener ==="
      puts <<-EOT

Que veux-tu faire :

  A. Ouvrir le projet préparé pour l'éditer, l'améliorer,
  B. Ouvrir une copie du projet préparé pour essayer les
     opérations ou les enregistrer.

      EOT

      case (getChar('>>>')||'').upcase
      when 'A' then true
      when 'B' then false
      else
        raise NotAnError.new("Je ne connais pas ce choix.")
      end
    end #/ask_for_prepared_or_copie

    # Ouvrir le document préparé
    def open_project_prepared
      `open -a Scrivener "#{path}"` # Il faut ouvrir l'original
      puts <<-EOT

  Ce document est le projet préparé du tutoriel, c'est-à-dire
  qu'il servira de base pour tout essai d'enregistrement. Une
  copie “de travail” en sera faite, qui pourra être détruite à
  la fin de l'essai ou de l'enregistrement.
  De cette manière, le projet préparé original ne sera jamais
  modifié et l'on pourra toujours repartir sur la même base.

      EOT
      `open -a Terminal`
    end

    def duplique_and_open
      File.unlink(copie_path) if copie_exists?
      FileUtils.cp_r(path, copie_path)
      `open -a Scrivener "#{copie_path}"`
      COMMAND.options[:quiet] && (return true)
      puts <<-EOT

  Ce document est une copie du projet préparé du tutoriel,
  elle peut être utilisé pour faire un essai des opérations
  ou les enregistrer sans problème.

  Il pourra ensuite être détruit.

      EOT
      `open -a Terminal`
    end

    def copie_exists?
      File.exists?(copie_path)
    end

    def copie_path
      @copie_path ||= vitefait.pathof("#{vitefait.name}.scriv")
    end

    def path
      @path ||= vitefait.pathof("#{vitefait.name}-prepared.scriv")
    end

  end #/ScrivenerProject

end #/ViteFait
