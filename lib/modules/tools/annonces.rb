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
      already_annonce_on_perso:"La publication sur ton site perso a déjà été faite. Veux-tu recommencer ?",
      infos_required: "Les informations complètes (titre, titre anglais, description) sont requises pour faire les annonces.\nPour les définir, utilisez :\n\n\tvite-faits infos %{name} titre=\"...\" titre_en=\"...\" description=\"...\"\n\n"
    }
  )

  def exec_annonce(pour = nil)
    type = pour || COMMAND.params[:pour] || COMMAND.params[:type]
    type || raise(NotAnError.new(MSG(:type_is_required)))
    infos_defined? || raise(NotAnError.new(MSG(:infos_required)))

    check_video_youtube || return

    case type.to_s
    when 'facebook', 'fb'
      annonce_fb
    when 'scrivener', 'scriv'
      annonce_scriv
    when 'perso'
      annonce_perso
    when 'both'
      annonce_fb
      annonce_scriv
      annonce_perso
    else
      error "Je ne connais pas le type d'annonce '#{type}'…"
    end
    puts "\n\n\n"
  rescue NotAnError => e
    error e.message
  end


  def check_video_youtube
    require_module('videos/youtube')
    youtube_id || not_an_error("L'identifiant YouTube n'est pas défini. Es-tu sûr d'avoir uploadé la vidéo ? (on ne peut rien annoncer sans youtube_id)")
    is_video_on_youtube? || not_an_error("Je ne trouve pas la vidéo sur YouTube. Es-tu sûr de l'avoir uploadée et programmée pour aujourd'hui ou avant ?")
    notice "J'ai trouvé la vidéo sur YouTube !"
    return true
  rescue NotAnError => e
    chaine_youtube # pour la rejoindre
    error(e.message)
    return false
  end

  # Assistant pour publier le tutoriel sur mon site perso
  def annonce_perso
    clear
    notice "=== Annonce sur philippeperret.fr ==="
    if informations[:annonce_perso]
      yesNo(MSG(:already_annonce_on_perso)) || return
    end

    notice <<-EOT
(la diffusion — publique — de la vidéo a été contrôlée)

Je vais ouvrir le site perso, à la rubrique Scrivener.
Et je t'indique ensuite la démarche à suivre.

    EOT
    Clipboard.copy(titre)
    sleep 2.5
    Clipboard.copy(video_url)
    sleep 2.5
    open_site_perso


    notice <<-EOT

Pour procéder à l'opération :

  * passe en édition à l'aide du lien 'connexion' tout
    en bas de page,
  * repère ou crée la rubrique où peut aller ce nouveau
    tutoriel,
  * duplique l'élément qui sert d'interligne entre les
    tutoriels,
  * duplique un tutoriel proche,
    Attention : la duplication n'est pas facile : il faut
    glisser la souris sur l'élément jusqu'à voir apparaitre
    'Modifier les colonnes', puis cliquer sur ce texte,
    et déplacer à l'aide de la poignée,
  * déplace-le à l'endroit voulu,
  * passe-le en édition,
  * sélectionne la vidéo et change l'url pour avoir la nouvelle
    (que j'ai mise dans le presse-papier),
  * sélectionne le texte et remplace-le par le titre
    “#{titre}”
    que j'ai placé dans PasteBox,
  * supprime le style (gomme) et mets la taille à 28px,
  * lie-le avec le lien :
    #{video_url}
    que j'ai aussi placé dans PasteBox.

    EOT

    # Marquer l'annonce déposée ?
    if yesNo("Dois-je marquer la publication faite sur ton site perso ?")
      informations.set(annonce_perso: true)
      save_last_logic_step
    end

  end



  def annonce_scriv

    clear
    notice "=== Annonce sur le forum Scrivener ==="

    if informations[:annonce_scriv]
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

    clear
    # Affichage du message
    puts "\n\n\nMessage :\n\n#{temp_annonce_scrivener}\n\n"
    notice "Message copié dans le presse-papier !"
    notice "(la présence — publique — de la vidéo a été contrôlée)"
    notice "ATTENTION ! Il faut charger la vignette avant de soumettre le message !\nElle se trouve à l'adresse : #{vignette_path}\n\n"
    decompte("Ouverture du forum dans %{nombre_secondes}", 10)
    # Ouvrir la page du forum pour créer le nouveau post
    forum_scrivener

    # Marquer l'annonce déposée ?
    if yesNo("Dois-je marquer l'annonce déposée sur Scrivener ?")
      informations.set(annonce_scriv: true)
      save_last_logic_step
    end

  end #/ annonce_scriv

  def annonce_fb
    clear
    notice "=== Annonce sur le groupe Facebook ==="

    if informations[:annonce_fb]
      yesNo(MSG(:already_facebook)) || return
    end

    puts "\n\nMessage :\n#{temp_annonce_facebook}\n"
    Clipboard.copy(temp_annonce_facebook)
    notice "Message copié dans le presse-papier !"
    notice "Il suffit de coller ce message dans un nouveau post sur le groupe."
    notice "(la présence — publique — de la vidéo a été contrôlée)\n\n"
    decompte("Ouverture du groupe Facebook dans %{nombre_secondes}…",10)
    groupe_facebook

    if yesNo("Dois-je marquer l'annonce sur Facebook faite ?")
      informations.set({annonce_fb: true})
      save_last_logic_step
    end
  end #/ annonce_fb

  def temp_annonce_facebook
    @temp_annonce_facebook ||= begin
      <<-EOT
📣 Je suis heureux de vous annoncer la diffusion d'un nouveau tutoriel “vite-fait” 🖥 . Il s'intitule “#{titre}”#{f_description(:facebook)}. Bon visionnage à vous ! 😄
#{video_url}
      EOT
    end
  end

  def temp_annonce_scrivener
    @temp_annonce_scrivener ||= begin
      <<-EOT
Bonjour à tous,

Dans la série des « Vite-faits », je suis heureux de vous annoncer un nouveau tutoriel !

[url=#{video_url}][size=150][b]#{titre}[/b][/size] [i](#{titre_en})[/i]#{f_description(:scrivener)}[/url]

[url=#{video_url}][attachment=0]Vignette.jpg[/attachment][/url]

[size=85]N'hésitez pas à le liker si vous l'appréciez (c'est une façon simple et gratuite d'encourager son créateur), à laisser des avis pour que les prochains soient encore meilleurs ou à proposer de nouveaux sujets que vous aimeriez voir développés. Merci à vous ![/size]

Bon visionnage !

Philippe Perret

      EOT
    end
  end

end
