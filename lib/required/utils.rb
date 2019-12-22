# encoding: UTF-8
=begin
  Méthodes utiles
=end

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
