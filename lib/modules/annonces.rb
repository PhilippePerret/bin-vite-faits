# encoding: UTF-8
=begin
  Module permettant de construire l'annonce scrivener et de la mettre dans le
  presse-papier
=end
class ViteFait

  def exec_annonce
    type = COMMAND.params[:pour] || COMMAND.params[:type]
    if type.nil?
      error "Il faut définir le type de l'annonce à produire :\n\n\tvite-faits annonce #{name} pour=scrivener|scriv|facebook|fb\n\nscrivener/scriv : pour le forum Latte & Litterature\nfacebook/fb : pour le groupe ”Scrivener en français” sur Facebook"
    else
      case type
      when 'facebook', 'fb'
        annonce_groupe_facebook
      when 'scrivener', 'scriv'
        annonce_forum_scrivener
      else
        error "Je ne connais pas le type d'annonce '#{type}'…"
      end
    end
  end

  def annonce_forum_scrivener
    if titre.nil?
      return error "Il faut définir le titre du tutoriel :\n\n\tvite-faits infos #{name} titre=\"LE TITRE\"\n\n"
    elsif titre_en.nil?
      return error "Il faut définir le titre anglais du tutoriel :\n\n\tvite-faits infos #{name} titre_en=\"THE TITLE\"\n\n"
    elsif youtube_id.nil?
      return error "Il faut définir l'identifiant YouTube de la vidéo\n(il faut donc qu'elle soit uploadée):\n\n\tvite-faits infos #{name} youtube_id=\"VIDEO_ID\"\n\n"
    elsif description.nil?
      return error "Il faut définir la description (en une ligne) du tutoriel :\n\n\tvite-faits infos #{name} description=\"DESCRIPTION\"\n\n"
    end
    notice "ATTENTION ! Il faut charger la vignette (qui se trouve à l'adresse : #{vignette_path})"

    # Mettre le message dans le presse-papier
    # TODO

    # Affichage du message
    puts "Le message sera : \n\n#{temp_annonce_scrivener}\n\n"

    # Ouvrir la page du forum pour créer le nouveau post
    # TODO

    # Rappel
    notice "ATTENTION ! Il faut charger la vignette (qui se trouve à l'adresse : #{vignette_path})"
  end

  def annonce_groupe_facebook
    puts "Je dois produire l'annonce pour le groupe Facebook"
  end


  def temp_annonce_scrivener
    fdescription =
      if description.nil? then '' else
        "\n“[i]#{description}[/i]”"
      end

    <<-EOT
Dans la série des « Vite-faits », je suis heureux de vous annoncer un nouveau tutoriel !

[url=https://www.youtube.com/watch?v=#{youtube_id}][size=150][b]#{titre}[/b][/size] [i](#{titre_en})[/i]#{fdescription}[/url]

[url=https://www.youtube.com/watch?v=#{youtube_id}][attachment=0]Vignette.jpg[/attachment][/url]

[size=85]N'hésitez pas à le liker si vous l'appréciez (c'est une façon simple et gratuite d'encourager son créateur), à laisser des avis pour que les prochains soient encore meilleurs ou à proposer de nouveaux sujets que vous aimeriez voir développés. Merci à vous ![/size]

Bon visionnage !

Philippe Perret

    EOT
  end
end
