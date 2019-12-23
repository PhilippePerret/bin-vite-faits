# encoding: UTF-8
=begin
  Méthodes utiles
=end


# Si +voix_dernier est défini, on dit les dernières
# valeurs avec cette voix (5, 4, 3, 2, 1)
def decompte phrase, fromValue, voix_dernier = false
  puts "\n\n"
  reste = fromValue.to_i
  phrase += " " * 20 + "\r"
  while reste > 0 # on ne dit pas zéro
    # Revenir à la 20e colonne de la 4è ligne
    # print "\033[4;24H"
    # print "\033[;24H"
    s = reste > 1 ? 's' : ''
    phrase_finale = phrase % {nombre_secondes: "#{reste} seconde#{s}"}
    print phrase_finale
    # print "Ouverture du forum dans #{reste} seconde#{s}              \r"
    if voix_dernier && reste < 6
      `say -v #{voix_dernier} "#{reste}"`
      sleep 0.5
    else
      sleep 1
    end
    reste -= 1
  end
  puts "\n\n\n"
end

# Méthode qui dit des textes
# Params:
#   +liste+:: [Array] La liste des choses à faire ou dire
#             Si l'élément est un [String], c'est un texte à dire.
#             Si l'élément est un string vide ou nil, c'est une pause (de
#             2 secondes ou de la longueur définie par params[:pause])
#             Si l'élément est {exec: "<code>"}, c'est du code à évaluer
#   +params+::  [Hash] Les paramètres
#               :pause    [Integer]   Nombre de secondes entre les actions
#               :voice    [String]    La voix à utiliser.
#
def dire_et_faire liste, params = nil
  params ||= {}
  params[:voice] ||= 'Audrey'
  params[:pause] ||= 2

  liste.each do |action|
    if action.is_a?(String)
      `say -v #{params[:voice]} "#{action}"`
    elsif action.to_s == ''
      sleep params[:pause]
    elsif action.is_a?(Hash) && action.key?(:exec)
      eval(action[:exec])
    end
    sleep 2
  end
end
alias :direEtFaire :dire_et_faire
alias :sayAndExec :dire_et_faire
