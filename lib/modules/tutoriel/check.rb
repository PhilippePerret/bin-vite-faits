# encoding: UTF-8
class ViteFait

  def exec_check
    check_logic_step
  end


  def check_logic_step
    require_module('tutoriel/conception')
    notice "Étape de conception courante enregistrée : #{informations[:logic_step]}"
    puts "Check de toutes les étapes de conception :"
    last_valide = nil
    an_invalid_found = false # pour s'arrêter dès qu'on trouve une invalide
    str_valide = "\033[1;32mOK\033[0m"
    str_invalide = "\033[1;31mTODO\033[0m"
    conception.steps.each do |step|
      puts "#{step.index.to_s.rjust(2)}. #{step.hname} : #{step.valid? ? str_valide : str_invalide}"
      stepIsValid = step.valid?(deep = true)
      if !an_invalid_found
        if stepIsValid
          last_valide = step.index
        else
          an_invalid_found = true
        end
      end
      if not stepIsValid
        puts "    ERRORS:#{step.errors_validity.inspect}"
      end
    end
    if last_valide != informations[:logic_step]
      error "La dernière étape enregistrée (#{informations[:logic_step]}) ne correspond pas au check (#{last_valide})"
      notice "Je corrige automatiquement cette information."
      save_last_logic_step
    end
  end

end #/ViteFait
