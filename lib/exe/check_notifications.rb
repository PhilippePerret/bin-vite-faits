#!/usr/bin/env ruby
# encoding: UTF-8
=begin

  Script appelé tous les jours par le cron-job pour savoir s'il faut
  notifier est tutoriels à annoncer

  Le crontab est :

  > crontab -e

  0  10 * * * ruby "/Users/philippeperret/Movies/Tutoriels/SCRIVENER/LES_VITE_FAITS/bin/lib/exe/check_notifications.rb"
  |  |  | | |_______ Tous les jours de la semaine
  |  |  | |_________ Tous les mois
  |  |  |___________ Tous les jours
  |  |_____________ À 10 heure
  |________________ À 00 minutes

=end
require 'yaml'
require 'date'

# Attention, c'est un THISFOLDER qui doit fonctionner avec le
# fichier constants.rb
THISFOLDER = File.dirname(File.dirname(File.expand_path(__FILE__)))
LIB_FOLDER = File.join(THISFOLDER,'lib')

# TODO On requiert juste ce qui est nécessaire
# Les constantes, qui permettent notamment d'avoir les données
# des lieux où on peut trouver les tutoriels
require_relative '../required/constants'
require_relative '../required/notification'

DATA_LIEUX.each do |klieu, dlieu|
  # puts dlieu.inspect
  folder = eval("VITEFAIT_#{klieu.to_s.upcase}_FOLDER")
  # puts "--- in: #{folder}"
  Dir["#{folder}/**/notifications.yaml"].each do |pth|
    tuto_name = File.basename(File.dirname(pth))
    notifications = YAML.load_file(pth)
    notifications.each do |dnotify|
      notify = Notification.new(dnotify.merge!(tuto_name: tuto_name))
      if notify.today? || notify.out_of_date?
        notify.notify
        sleep 3
      else
        # Notification future
      end
    end
  end
end
