# encoding: UTF-8
=begin

  Extension de la class Command pour l'application
=end
class Command

  attr_accessor :action, :folder,

  def self.after_decompose
    COMMAND.action = COMMAND.args[0]
    COMMAND.folder = COMMAND.args[1]
    # puts "COMMAND.action = #{COMMAND.action.inspect}"
    # puts "COMMAND.folder = #{COMMAND.folder.inspect}"
  end

end #/Command
