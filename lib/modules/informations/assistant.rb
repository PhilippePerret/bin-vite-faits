# encoding: UTF-8
=begin
  Assistant de demande des informations générales
=end
def exec(options = nil)
  # Les informations générales dont on a besoin
  clear
  notice "\n===Informations générales ==="
  ask_for_titre           unless titre
  ask_for_titre_en        unless titre_en
  ask_for_description     unless description
  ask_for_publishing_date unless published_at
  # On enregistre les informations
  if titre || titre_en || description || published_at
    informations.set({titre: titre, titre_en:titre_en, description:description, published_at:published_at})
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
(mais vous pourrez toujours le redéfinir par :

    vitefait infos #{name} titre="new_titre")

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

    vitefait infos #{name} titre_en='new_titre')

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

# Méthode pour demander la date de publication
def ask_for_publishing_date
  puts <<-EOT

= Date de publication =
Quelle est la date prévue pour la publication ?
Au format : JJ MM AAAA

  EOT
  while true
    date = prompt("Date publication")
    if date.nil?
      puts "OK, pas de date de publication pour le moment…"
      return true
    else
      if published_date_valid?(date)
        @published_at = res
        return true
      end
    end
  end
end

def published_date_valid?(date)
  j,m,a = date.split(' ')
  inst = Date.parse("#{a} #{m} #{j}")
  if inst < Date.today
    error "La date de publication doit être dans le futur, voyons…"
    return false
  end
  return true
end
