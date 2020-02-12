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

# Pré-transformations de commandes
COMMAND.action =  case COMMAND.action
                  when 'montage' then 'open-montage'
                  else COMMAND.action
                  end

COMMAND_TIRET = COMMAND.action.gsub(/_/,'-')
case COMMAND_TIRET
when 'try'
  # Pour essayer une méthode, un code, etc.
  if vitefait.is_required
    res = vitefait.montage_manuel?
    puts "Montage manuel ? #{res.inspect}"
  end
when 'help', 'manuel', 'aide'
  ViteFait.open_help
when 'idees'
  ViteFait.open_idee_file
when 'conception'
  ViteFait.aide_conception
when 'test'
  ViteFait.test
when 'current', 'courant'
  ViteFait.show_current_name
when 'list', 'liste'
  ViteFait.list.display
when 'open'
  ViteFait.open(COMMAND.folder)
when 'open-captures'
  ViteFait.open('captures')
when /^open[\-_](.*)$/
  vitefait.is_required && vitefait.open_something($1)
when /^record[\-_](.*)$/
  vitefait.is_required && vitefait.record_something($1)
when /^voir[\-_](.*)$/
  vitefait.is_required && vitefait.voir_something($1)
when /^check[\-_](.*)$/
  vitefait.is_required && vitefait.check_something($1)
when 'url-video', 'url_video'
  vitefait.is_required && vitefait.voir_something('url_video')
when 'crop'
  vitefait.is_required && vitefait.crop
when 'assistant'
  ViteFait.assistant
when 'create'
  if COMMAND.options[:assistant]
    ViteFait.assistant
  else
    vitefait.name_is_required || vitefait.create
  end
when 'move','deplace', 'deplacer'
  vitefait.is_required && vitefait.move
when 'backup'
  if COMMAND.folder == 'all'
    ViteFait.update_all_backups
  else
    vitefait.is_required && vitefait.backup
  end
when 'rapport', 'report'
  vitefait.is_required && vitefait.write_rapport
when 'check'
  vitefait.is_required && vitefait.check
when 'lire-operations'
  vitefait.is_required && vitefait.record_operations
when 'capture-to-mp4', 'traite-capture'
  vitefait.is_required && vitefait.capture_to_mp4
when /^assemble[\-_](.*)$/
  vitefait.is_required && vitefait.assemble_something($1)
when 'assemble'
  vitefait.is_required && vitefait.assemble
when 'update'
  vitefait.is_required && vitefait.update_from
when 'edit-voice'
  vitefait.is_required && vitefait.edit_voice_file
when 'keep-only'
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
when 'chaine-youtube', 'open-youtube'
  vitefait.chaine_youtube
when 'groupe-facebook'
  vitefait.groupe_facebook
when 'forum-scrivener'
  vitefait.forum_scrivener
when 'operations'
  vitefait.commande_operations
when 'taches', 'tache'
  vitefait.is_required && vitefait.commande_taches
when 'notifications', 'notification'
  vitefait.is_required && vitefait.commande_notifications
when NilClass
  error <<-EOT
🚫  Il faut définir la commande à jouer ! Taper
`vitefait aide` ou `vitefait manuel` pour
obtenir de l'aide en ouvrant le manuel.
  EOT
else
  error "🚫  Impossible de traiter la commande #{COMMAND.action} (#{COMMAND_TIRET})."
end

ViteFait.finish
# Notamment pour enregistrer le tutoriel courant et
# la date
