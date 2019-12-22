#!/usr/bin/env ruby
# encoding: UTF-8

require_relative 'lib/required.rb'

ViteFait.init

Command.decompose
# => COMMAND

# Pour vite-faits.rb -h/--help
if COMMAND.options[:help] && COMMAND.action.nil?
  COMMAND.action = 'help'
end

case COMMAND.action
when 'help', 'manuel'
  ViteFait.open_help
when 'current', 'courant'
  ViteFait.show_current_name
when 'list', 'liste'
  ViteFait.list.display
when 'open'
  ViteFait.open(COMMAND.folder)
when 'assistant'
  ViteFait.assistant
when 'create'
  vitefait.name_is_required || vitefait.create
when 'move','deplace', 'deplacer'
  vitefait.is_required && vitefait.move
when 'rapport', 'report'
  vitefait.is_required && vitefait.write_rapport
when 'lire_operations'
  vitefait.is_required && vitefait.record_operations
when 'capture_to_mp4', 'traite_capture'
  vitefait.is_required && vitefait.capture_to_mp4
when 'titre_to_mp4', 'traite_titre'
  vitefait.is_required && vitefait.titre_to_mp4
when 'montage'
  vitefait.is_required && vitefait.open_montage
when 'assemble'
  vitefait.is_required && vitefait.assemble
when 'assemble_capture'
  vitefait.is_required && vitefait.assemble_capture
when 'open_scrivener'
  vitefait.is_required && vitefait.open_scrivener_project
when 'open_vignette', 'edit_vignette'
  vitefait.is_required && vitefait.open_vignette
when 'open_titre'
  vitefait.is_required && vitefait.open_titre
when 'operations'
  vitefait.is_required && vitefait.open_operations_file
when 'keep_only'
  vitefait.is_required && vitefait.keep_only_folder
when 'upload'
  vitefait.is_required && vitefait.upload
when 'infos'
  vitefait.is_required && vitefait.informations.touch
when 'annonce'
  vitefait.is_required && vitefait.annonce
when 'annonces'
  vitefait.is_required && vitefait.annonce(:both)
when 'remove', 'destroy', 'detruire', 'supprimer', 'delete'
  vitefait.is_required && vitefait.destroy
when 'chaine_youtube', 'open_youtube'
  vitefait.chaine_youtube
when 'groupe_facebook'
  vitefait.groupe_facebook
when 'forum_scrivener'
  vitefait.forum_scrivener
else
  error "Impossible de traiter l'action #{COMMAND.action}"
end

ViteFait.finish
# Notamment pour enregistrer le tutoriel courant et
# la date
