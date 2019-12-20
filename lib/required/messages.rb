def error msg, options = {}
  puts "\033[1;31m#{msg}\033[0m"
  return false
end
def notice msg, options = {}
  COMMAND.options[:silence] || puts("\033[1;32m#{msg}\033[0m")
end

def write_green msg
  puts "\033[1;32m#{msg}\033[0m"
end
def write_purple msg
  puts "\033[1;34m#{msg}\033[0m"
end
def write_yellow msg
  puts "\033[1;33m#{msg}\033[0m"
end
def write_fushia msg
  puts "\033[1;35m#{msg}\033[0m"
end
def write_cyan msg
  puts "\033[1;36m#{msg}\033[0m"
end


class TempMSG
class << self
  # Retourne le message d'identifiant +msg_id+ avec les
  # variables +params+
  def get msg_id, params = nil
    @MSG_DATA[msg_id] % default_variables.merge(params||{})
  end
  def add_messages(table)
    # Ajout de données
    @MSG_DATA ||= {}
    @MSG_DATA.merge!(table)
  end
  # Variables par défaut en fonction de l'application
  def default_variables
    MSG_default_variables() || {}
  end
end #/<< self
end #/ TempMSG

# Gestion des messages template
# -----------------------------
# @param {Symbol} msg_id
#                 Quand c'est un symbol, msg_id définit le message à retourner
# @param {Hash}   msg_id
#                 Quand c'est une table, msg_id définit les messages à ajouter
# @param {Hash}   params
#                 La définition optionnelle des variables.
#
# Usage
# -----
#   Utiliser en début de module :
#     MSG({
#       cle_message: "message avec %{variable}"
#       cle_message: "message avec %{variable}"
#     })
#   … pour définir les messages propres
#
#   Utiliser dans le programme
#     MSG(msg_id[, params])
#   … pour obtenir le message en question.
def MSG msg_id, params = nil
  if msg_id.is_a?(Symbol)
    # Renvoie du message formaté
    TempMSG.get(msg_id, params)
  else
    TempMSG.add_messages(msg_id)
  end
end
