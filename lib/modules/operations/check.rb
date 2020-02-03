# encoding: UTF-8
=begin
  Module qui checke la validité des opérations définies

=end
class ViteFait

  # Cette méthode s'assure que le fichier des opérations est conforme
  # On peut l'appeler par 'vitefait check-operations' ou
  # 'vitefait operations -c'
  def check_operations_file
    errors = []

    clear
    notice <<-EOT
Vérification du fichier des opérations
--------------------------------------

    EOT

    operations_defined? || raise("Le fichier opération n'est pas défini. Je ne peux pas le checker.")
    notice "✔︎ Le fichier operations.yaml est défini"
    # Il faut pouvoir le lire (la méthode génère une erreur
    # si le fichier ne peut pas être lu)
    opes = get_operations
    notice "✔︎ Le fichier operations.yaml peut être parsé par YAML sans erreur."

    # Ensuite on va prendre le code proprement dit, sans le parser par
    # YAML, pour voir si des id ne sont pas redondants
    errors_doublon_id = 0
    code = File.read(operations_path).force_encoding('utf-8')
    key_list = {}
    File.open(operations_path,'r').readlines.each do |line|
      if line.include?(' id:')
        avant, id = line.split('id:')
        id = id.strip
        if key_list.key?(id)
          errors << "La clé (id:) '#{id}' est utilisée deux fois !"
          errors_doublon_id += 1
        else
          key_list.merge!(id => true)
        end
      end
    end
    notice "✔︎ Pas de doublon d'ID" if errors_doublon_id == 0

    # Chaque opération doit contenir les bonnes données
    init_errors_count = errors.count
    opes.each do |ope|
      ope.key?(:id)     || errors << "Opération #{ope[:titre]} n'a pas d'ID"
      ope.key?(:titre)  || errors << "Opération ##{ope[:id]} n'a pas de :titre"
      ope.key?(:voice)  || errors << "La voix (voice:) n'est pas définie dans l'opération ##{ope[:id]}"
      ope.key?(:action) || errors << "L'action (action:) n'est pas définie dans l'opération ##{ope[:id]}"
      ope_id = ope[:id]
      [:id, :titre, :voice, :action, :duration].each do |key|
        ope.delete(key)
      end
      ope.keys.count == 0 || errors << "L'opération #{ope_id} contient des clés inconnues : #{ope.keys.join(', ')}"
    end
    if init_errors_count == errors.count
      notice "✔︎ Les données des opérations sont bien définies"
    end

    if errors.count > 0
      raise errors.join("\n")
    end

    return true
  rescue Exception => e
    error "Des erreurs ont été rencontrées :"
    error "---------------------------------"
    error "\t- " + e.message.gsub(/\n/,"\n\t- ")
    return false
  ensure
    puts "\n\n"
  end
end #/ ViteFait
