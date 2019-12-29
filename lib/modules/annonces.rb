# encoding: UTF-8
=begin
  Module permettant de construire l'annonce scrivener et de la mettre dans le
  presse-papier
=end
class ViteFait

  MSG(
    {
      type_is_required:"Il faut définir le type de l'annonce à produire :\n\n\tvite-faits annonce %{name} pour=scrivener|scriv|facebook|fb\n\nscrivener/scriv : pour le forum Latte & Litterature\nfacebook/fb : pour le groupe ”Scrivener en français” sur Facebook",
      already_facebook:"L'annonce sur le groupe Facebook a déjà été faite. Dois-je recommencer ?",
      already_scrivener:"L'annonce sur le forum Scrivener a déjà été faite. Dois-je recommencer ?",
      infos_required: "Les informations complètes (titre, titre anglais, description) sont requises pour faire les annonces.\nPour les définir, utilisez :\n\n\tvite-faits infos %{name} titre=\"...\" titre_en=\"...\" description=\"...\"\n\n"
    }
  )

  def exec_annonce(pour = nil)
    type = pour || COMMAND.params[:pour] || COMMAND.params[:type]
    type || raise(NotAnError.new(MSG(:type_is_required)))
    infos_defined? || raise(NotAnError.new(MSG(:infos_required)))

    case type.to_s
    when 'facebook', 'fb'
      annonce_FB
    when 'scrivener', 'scriv'
      annonce_Scriv
    when 'both'
      annonce_FB
      annonce_Scriv
    else
      error "Je ne connais pas le type d'annonce '#{type}'…"
    end
    puts "\n\n\n"
  rescue NotAnError => e
    error e.message
  end

  def annonce_Scriv

    clear
    notice "=== Annonce sur le forume Scrivener ==="

    if informations[:annonce_Scriv]
      yesNo(MSG(:already_scrivener)) || return
    end

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

    # Marquer l'annonce déposée ?
    if yesNo("Dois-je marquer l'annonce déposée sur Scrivener ?")
      informations.set(annonce_Scriv: true)
      save_last_logic_step
    end

  end #/ annonce_Scriv

  def annonce_FB
    clear
    notice "=== Annonce sur le groupe Facebook ==="

    if informations[:annonce_FB]
      yesNo(MSG(:already_facebook)) || return
    end

    puts "\n\nMessage :\n#{temp_annonce_facebook}\n"
    Clipboard.copy(temp_annonce_facebook)
    notice "Message copié dans le presse-papier !"
    notice "Il suffit de coller ce message dans un nouveau post sur le groupe."
    notice "S'assurer que la vidéo a bien été placée.\n\n"
    decompte("Ouverture du groupe Facebook dans %{nombre_secondes}…",10)
    groupe_facebook

    if yesNo("Dois-je marquer l'annonce sur Facebook faite ?")
      informations.set({annonce_FB: true})
      save_last_logic_step
    end
  end #/ annonce_FB

  def temp_annonce_facebook
    @temp_annonce_facebook ||= begin
      <<-EOT
Je suis heureux de vous annoncer 📣 la diffusion d'un nouveau tutoriel “vite-fait” 🖥. Il s'intitule “#{titre}”#{f_description(:facebook)}. Bon visionnage à vous !
#{video_url}
      EOT
    end
  end

  def temp_annonce_scrivener
    @temp_annonce_scrivener ||= begin
      <<-EOT
Bonjour à tous,

🥁 Dans la série des « Vite-faits », je suis heureux de vous annoncer un nouveau tutoriel ! 📣

[url=#{video_url}][size=150][b]#{titre}[/b][/size] [i](#{titre_en})[/i]#{f_description(:scrivener)}[/url]

[url=#{video_url}][attachment=0]Vignette.jpg[/attachment][/url]

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
