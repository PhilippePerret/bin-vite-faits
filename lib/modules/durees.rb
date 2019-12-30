# encoding: UTF-8
=begin
  Module permettant de calculer ou d'estimer la durée
  du tutoriel
=end
class ViteFait

  # Retourne la durée du tutoriel sous forme d'horloge
  def tutoriel_hduration
    tutoriel_duration.round.as_horloge
  end
  # Retourne la durée du tutoriel en secondes, estimée ou réelle
  def tutoriel_duration
    @tutoriel_duration ||= begin
        intro_duration +
        titre_duration +
        operations_duration +
        final_duration
    rescue Exception => e
      error "Impossible d'estimer la durée du tutoriel : #{e.message}\n(je mets 5 minutes à titre préventif)"
      5 * 60
    end
  end

  # Retourne le "type humain de durée" qui précise sur la base de
  # quels fichiers a été estimée la durée du tutoriel.
  def htype_duration
    @htype_duration ||= begin
      if type_duration == 100
        'Durée exacte'
      elsif type_duration > 50
        'Durée bien estimée'
      elsif type_duration > 25
        'Durée estimée'
      else
        'Durée approximative'
      end
    end
  end

  # Retourne le "type de durée" qui précise sur la base de quels
  # fichiers a été estimée la durée totale du tutoriel.
  # Plus le chiffre est élevée, plus la durée est proche du final
  def type_duration
    @type_duration ||= begin
      if File.exists?(record_operations_completed)
        100 # le max
      else
        bitvalue = 0
        if operations_recorded?
          bitvalue += 50
        elsif operations_defined?
          bitvalue += 25
        end
        if titre_finalized?
          bitvalue += 10
        elsif titre_recorded?
          bitvalue += 5
        end
        bitvalue
      end
    end
  end

  def operations_duration
    @operations_duration ||= begin
      if operations_recorded?
        Video.dureeOf(record_operations_path)
      elsif operations_defined?
        # Si le fichier des opérations est déterminé, on
        # peut estimer le temps en fonction des opérations
        require_module('operations')
        duree_totale_estimee
      else
        # Sinon, on donne une valeur vraiment arbitraire
        30
      end
    end
  end

  def titre_duration
    @titre_duration ||= begin
      if titre_finalized?
        Video.dureeOf(record_titre_mp4)
      elsif titre_recorded?
        Video.dureeOf(titre_mov) - 1
      else
        20 # par défaut, pour avoir une durée
      end
    end
  end

  def intro_duration
    @intro_duration ||= begin
      intro_file = if has_own_intro?
                      own_intro_mp4
                    elsif File.exists?(self.class.intro_ts)
                      self.class.intro_ts
                    else
                      self.class.intro_mp4
                    end
      Video.dureeOf(intro_file)
    end
  end

  def final_duration
    @final_duration ||= begin
      final_file =  if has_own_final?
                      own_final_mp4
                    elsif File.exists?(self.class.final_ts)
                      self.class.final_ts
                    else
                      self.class.final_mp4
                    end
      Video.dureeOf(final_file)
    end
  end
end
