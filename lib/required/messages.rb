def error msg, options = {}
  puts "\033[1;31m#{msg}\033[0m"
  return false
end
def notice msg, options = {}
  COMMAND.options[:silence] || puts("\033[1;32m#{msg}\033[0m")
end
# Pour écrire une ligne qui va disparaitre au prochain
# message.
def notice_prov msg
  COMMAND.options[:silence] || print("\033[1;32m#{msg}\033[0m\r")
end
def warn msg, options = {}
  write_yellow msg
end

def write_green msg
  puts "\033[1;32m#{msg}\033[0m"
end
# def write_orange msg
#   (20..90).each do |i|
#     puts "#{i} : \033[1;#{i}m#{msg}\033[0m"
#   end
# end
def write_gras msg
  puts "\033[1;38m#{msg}\033[0m"
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
def write_grey msg
  puts "\033[1;90m#{msg}\033[0m"
end


class TempMSG
class << self
  attr_reader :MSG_DATA
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
# +Params+
#   +msg_id+::  [Symbol]  ID du message à retourner.
#               [Hash]    Table des messages
#   +params+::  [Hash]    Table des variables
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

# Retourne true si la donnée message +msg_id+ existe
def msg_exists? msg_id
  return TempMSG.MSG_DATA && TempMSG.MSG_DATA.key?(msg_id.to_sym)
end
