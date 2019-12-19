# encoding: UTF-8
=begin
  Module permettant de construire l'annonce scrivener et de la mettre dans le
  presse-papier
=end
class ViteFait

  def exec_annonce(pour = nil)
    type = pour || COMMAND.params[:pour] || COMMAND.params[:type]
    if type.nil?
      error "Il faut définir le type de l'annonce à produire :\n\n\tvite-faits annonce #{name} pour=scrivener|scriv|facebook|fb\n\nscrivener/scriv : pour le forum Latte & Litterature\nfacebook/fb : pour le groupe ”Scrivener en français” sur Facebook"
    else
      case type.to_s
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

    Clipboard.copy(temp_annonce_scrivener)
    notice "Il suffit de coller ce message dans un nouveau post sur le forum."

    Command.clear_terminal
    # Affichage du message
    puts "\n\n\nMessage :\n\n#{temp_annonce_scrivener}\n\n"
    notice "Message copié dans le presse-papier !"
    notice "ATTENTION ! Il faut charger la vignette avant de soumettre le message !\nElle se trouve à l'adresse : #{vignette_path}\n\n"
    decompte("Ouverture du forum dans %{nombre_secondes}", 10)
    # Ouvrir la page du forum pour créer le nouveau post
    forum_scrivener
  end

  def annonce_groupe_facebook
    Command.clear_terminal
    puts "\n\nMessage :\n#{temp_annonce_facebook}\n"
    Clipboard.copy(temp_annonce_facebook)
    notice "Message copié dans le presse-papier !"
    notice "Il suffit de coller ce message dans un nouveau post sur le groupe."
    notice "S'assurer que la vidéo à bien été placée.\n\n"
    decompte("Ouverture du groupe Facebook dans %{nombre_secondes}…",10)
    groupe_facebook
  end

  def temp_annonce_facebook
    @temp_annonce_facebook ||= begin
      <<-EOT
Je suis heureux de vous annoncer 📣 la diffusion d'un nouveau tutoriel “vite-fait” 🖥. Il s'intitule “#{titre}”#{f_description(:facebook)}. Bon visionnage à vous !
https://www.youtube.com/watch?v=#{youtube_id}
      EOT
    end
  end

  def temp_annonce_scrivener
    @temp_annonce_scrivener ||= begin
      <<-EOT
Bonjour à tous,

🥁 Dans la série des « Vite-faits », je suis heureux de vous annoncer un nouveau tutoriel ! 📣

[url=https://www.youtube.com/watch?v=#{youtube_id}][size=150][b]#{titre}[/b][/size] [i](#{titre_en})[/i]#{f_description(:scrivener)}[/url]

[url=https://www.youtube.com/watch?v=#{youtube_id}][attachment=0]Vignette.jpg[/attachment][/url]

[size=85]N'hésitez pas à le liker si vous l'appréciez (c'est une façon simple et gratuite d'encourager son créateur), à laisser des avis pour que les prochains soient encore meilleurs ou à proposer de nouveaux sujets que vous aimeriez voir développés. Merci à vous ![/size]

Bon visionnage !

Philippe Perret

      EOT
    end
  end

  def f_description(pour)
    @f_description ||= begin
      if description.nil?
        ''
      else
        if pour == :scrivener
          "\n“[i]#{description}[/i]”"
        elsif pour == :facebook
          " (#{description})"
        end
      end
    end
  end

end
