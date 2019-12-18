#!/usr/bin/env ruby
# encoding: UTF-8

require_relative 'lib/required.rb'

Command.decompose
# => COMMAND

# Pour vite-faits.rb -h/--help
if COMMAND.options[:help] && COMMAND.action.nil?
  COMMAND.action = 'help'
end

case COMMAND.action
when 'complete'
  vitefait.name_is_required || vitefait.complete
when 'create'
  vitefait.name_is_required || vitefait.create
when 'help', 'manuel'
  ViteFait.open_help
when 'open'
  ViteFait.open(COMMAND.folder)
when 'assistant'
  ViteFait.assistant
when 'rapport', 'report'
  vitefait.name_is_required || vitefait.write_rapport
when 'capture_to_mp4', 'traite_capture'
  vitefait.name_is_required || vitefait.capture_to_mp4
when 'titre_to_mp4', 'traite_titre'
  vitefait.name_is_required || vitefait.titre_to_mp4
when 'montage'
  vitefait.name_is_required || vitefait.open_montage
when 'assemble'
  vitefait.name_is_required || vitefait.assemble
when 'open_vignette', 'edit_vignette'
  vitefait.name_is_required || vitefait.open_vignette
when 'open_titre'
  vitefait.name_is_required || vitefait.open_titre
when 'upload'
  vitefait.name_is_required || vitefait.upload
when 'infos'
  vitefait.name_is_required || vitefait.informations.touch
when 'annonce'
  vitefait.name_is_required || vitefait.annonce
when 'chaine_youtube'
  vitefait.chaine_youtube
when 'groupe_facebook'
  vitefait.groupe_facebook
when 'forum_scrivener'
  vitefait.forum_scrivener
else
  error "Impossible de traiter l'action #{COMMAND.action}"
end
