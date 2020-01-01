# encoding: UTF-8
=begin
  Module d'assistance de la création de la vignette
=end
def exec(options = nil)
  clear
  notice "Nous devons créer LA VIGNETTE"

  open_something('vignette', edition = true)
  `open -a Terminal`

  puts <<-EOT

Cette vignette sera utile dans *YouTube* et sur le
*forum Scrivener*. Je vais ouvrir le modèle.
Il suffira de :

- régler le titre,
- exporter l'image au format JPEG.

Noter que ce fichier Gimp est une copie de l'original.
On peut donc le modifier et l'enregistrer sans souci.

Le titre à écrire est :

    « #{titre} ».

  EOT

  yesOrStop("Tape 'y' lorsque tu auras fini.")

  if vignette_finale_existe?
    save_last_logic_step
  else
    error "Tu n'as pas créé la vignette finale… Poursuivons quand même."
  end

end
