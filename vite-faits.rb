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
when 'help'
  ViteFait.open_help
when 'open'
  ViteFait.open(COMMAND.folder)
when 'rapport', 'report'
  vitefait.write_rapport
else
  error "Impossible de traiter l'action #{COMMAND.action}"
end
