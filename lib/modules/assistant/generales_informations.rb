# encoding: UTF-8
=begin
  Assistant de demande des informations générales
=end
def exec(options = nil)
  # Les informations générales dont on a besoin
  clear
  notice "\n===Informations générales ==="
  ask_for_titre        unless titre
  ask_for_titre_en     unless titre_en
  ask_for_description  unless description
  # On enregistre les informations
  if titre || titre_en || description
    informations.set({titre: titre, titre_en:titre_en, description:description})
    # notice "Informations enregistrées."
  else
    notice "Aucune information pour le moment. Il faudra penser à les rentrer."
  end
end

def ask_for_titre
  puts <<-EOT

= Titre humain =
Nous devons déterminer le titre humain du tutoriel.
Le choisir avec soin car il sera utilisé dans les
annonces et autre.
(mais vous pourrez toujours le redéfinir par vite-

    faits infos #{name} titre='new_titre')

  EOT
  res = prompt("Titre humain")
  if res.nil?
    puts "OK, pas de titre pour le moment…"
  else
    @titre = res
  end
end

def ask_for_titre_en
  puts <<-EOT

= Titre anglais =
J'ai besoin du titre anglais (pour le forum Scrivener).
(tu pourras toujours le redéfinir par :

    vite-faits infos #{name} titre_en='new_titre')

  EOT
  res = prompt("Titre anglais")
  if res.nil?
    puts "OK, pas de titre anglais pour le moment…"
  else
    @titre_en = res
  end
end

def ask_for_description
  puts <<-EOT

= Description =
Une description en une phrase, pour accompagner les
messages.

  EOT
  res = prompt("Description")
  if res.nil?
    puts "OK, pas de description pour le moment…"
  else
    @description = res
  end
end
