# encoding: UTF-8
=begin

  Code appelé par l'assistant que le tutoriel existe déjà
  et qu'il est peut-être même achevé.

=end
def exec(tuto, options = nil)
  # Si le tutoriel est déjà achevé est annoncé, rien à faire
  if tuto.completed_and_published?
    if COMMAND.options[:force]
      error "Désolé, je ne sais pas encore forcer l'assistant à traiter une création forcée."
      return error "Vous pouvez, en attenand, détruire certains éléments manuellement."
    else
      notice "Le tutoriel “#{tuto.titre}” est déjà achevé et publié. Il n'y a plus rien à faire dessus…"
      puts "Si vraiment, tu veux recommencer utilise l'option `--force` avec l'assistant."
      return
    end
  end

  yesOrStop("Ce tutoriel existe déjà. Dois-je en poursuivre la création ?")
  puts "Poursuite de la création de #{tuto.name}. Faisons le point…"

end
