# encoding: UTF-8
=begin

  Module pour demander le nom du tutoriel

  Retourne le nom choisi, ou nil pour arrêter

=end
def exec(options = nil)
  tuto_name = nil
  begin
    tuto_name = prompt("Nom du tutoriel (minuscules et '-')")
    if tuto_name.nil?
      if yesNo('Voulez-vous vraiment arrêter ?')
        raise NotAnError.new(nil)
      end
    end
    if (tuto_name||'').gsub(/[a-z\-]/,'') != ''
      error "Un nom de tutoriel ne doit comporter que des lettres minuscules et le signe moins."
      tuto_name = nil
    end
  end while tuto_name.nil?

  return tuto_name
end
