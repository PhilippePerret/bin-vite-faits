# encoding: UTF-8
=begin
  Destruction d'un tutoriel vite-faits
=end
class ViteFait

  # Exécutation de la destruction du vite-fait
  def exec_destroy
    designation = "le tutoriel '#{name}'"
    titre && designation << " de titre « #{titre} »"
    yesNo("Voulez-vous vraiment détruire #{designation} ?") || return
    yesNo("Tous ses éléments seront détruits, tous.\nVeux-tu vraiment procéder à cette opération ?") || return
    puts "OK…"
    proceed_destroy
  end

  def proceed_destroy
    IO.remove_with_care(current_folder, "dossier du tutoriel", true)
  end


end
