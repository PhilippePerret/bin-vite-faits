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
require 'json'
require 'date'

# Attention, c'est un THISFOLDER qui doit fonctionner avec le
# fichier constants.rb
THISFOLDER = File.dirname(File.dirname(File.expand_path(__FILE__)))
LIB_FOLDER = File.join(THISFOLDER,'lib')

# On requiert juste ce qui est nécessaire
# Les constantes, qui permettent notamment d'avoir les données
# des lieux où on peut trouver les tutoriels
require_relative '../required/constants'
require_relative '../required/notification'

today_string = Date.today.strftime('%d %m %Y')
# puts "today_string = '#{today_string}'"

DATA_LIEUX.each do |klieu, dlieu|
  # puts dlieu.inspect

  folder = eval("VITEFAIT_#{klieu.to_s.upcase}_FOLDER")
  # puts "--- in: #{folder}"

  # Voir si des tutoriels sont publiés aujourd'hui
  Dir["#{folder}/**/infos.json"].each do |pth|
    begin
      tuto_name = File.basename(File.dirname(pth))
      tuto_infos = JSON.parse(File.read(pth))
      published_at = tuto_infos['published_at']
      published_at || next
      published_at = published_at['value']
      # Seulement si défini
      if published_at === today_string
        # OK, c'est aujourd'hui !
        notif = Notification.new({titre:'Publication', date:published_at, tuto_name:tuto_name, message:"Contrôler et annoncer la publication aujourd'hui du tutoriel “#{tuto_infos['titre']['value']}” (dossier : '#{tuto_name}')"})
        notif.notify
        sleep 3
      end
    rescue Exception => e
      puts "Un problème s'est produit avec le fichier '#{pth}'"
      puts e.message
      puts e.backtrace.join("\n")
    end
  end

  # Voir si des notifications sont à lancer
  Dir["#{folder}/**/notifications.yaml"].each do |pth|
    begin
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
    rescue Exception => e
      puts "Un problème s'est produit avec le fichier '#{pth}'"
      puts e.message
      puts e.backtrace.join("\n")
    end
  end
end
