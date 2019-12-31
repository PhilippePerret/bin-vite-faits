# encoding: UTF-8
=begin

  class Notification
  ------------------
  Gestion des notifications
  Attention : doit pouvoir fonctionner "seule" car elle est
  utilisée par le cronjob pour vérifier s'il y a des
  notifications à donner

=end
require 'date'
NOTIFIER_CMD = "/Users/philippeperret/.rbenv/versions/2.6.3/bin/terminal-notifier"

class Notification
  # ---------------------------------------------------------------------
  #   CLASS
  # ---------------------------------------------------------------------
  class << self
    def today_strg
      @today_strg ||= today.strftime('%Y %m %d')
    end
    def today
      @today ||= Date.today
    end
    def appIcon
      @appIcon ||= File.join(BIN_FOLDER,'..','Materiel','Logo.icns')
    end
  end #/<<self


  # ---------------------------------------------------------------------
  #   INSTANCE
  # ---------------------------------------------------------------------

  attr_reader :data
  attr_reader :id, :titre, :message, :date, :tuto_name
  def initialize data, tuto = nil
    @data = data
    @tuto = tuto
    dispatch(data)
  end

  def dispatch(newdata)
    newdata.each do |k,v|
      instance_variable_set("@#{k}", v)
      @data[k] = v
    end
    # exit unless newdata.key?(:id)
  end

  # Notifier
  # Normalement, avec -sender, on n'a pas besoin de préciser l'icone
  # avec ', -appIcon \"#{mere.appIcon}\"', qui pourrait changer à
  # l'avenir du développement de terminal-notifier
  def notify
    cmd = "#{NOTIFIER_CMD} -ignoreDnD -title \"#{real_titre}\" -message \"#{real_message}\" -sound 'default' -sender 'com.apple.ViteFait'"
    `#{cmd}`
  end

  def real_message
    @real_message ||= begin
      if out_of_date?
        "!!! #{message}"
      else
        message
      end
    end
  end

  # Le titre qui sera affiché, notamment avec le
  # titre du tutoriel (son dossier) pour savoir qui
  # envoie cette notification.
  def real_titre
    "#{tuto_name} ›› #{titre}"
  end

  # ---
  #   States
  # ---

  # Retourne true si la notification doit être donnée aujourd'hui
  def today?
    date_strg == mere.today_strg
  end
  def out_of_date?
    real_date < mere.today
  end

  def real_date
    @real_date ||= Date.parse(date.gsub(/ /,'/'))
  end
  def date_strg # pour la clarté
    date
  end

  def mere; @mere ||= self.class end

end #/Notification
