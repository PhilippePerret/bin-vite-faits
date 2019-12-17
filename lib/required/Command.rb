# encoding: UTF-8
class Command

  class << self

    # Analyse la ligne de commande courante
    def decompose
      ARGV.each do |arg|
        if arg.start_with?('-')
          key = arg.start_with?('--') ? arg[2..-1] : MIN_OPT_TO_REAL_OPT[arg[1..-1]]
          COMMAND.options.merge!(key.to_sym => true)
        elsif arg.include?('=')
          key, val = arg.split('=')
          COMMAND.params.merge!(key.to_sym => val)
        elsif COMMAND.action.nil?
          COMMAND.action = arg
        elsif COMMAND.folder.nil?
          COMMAND.folder = arg
        end
      end
      # puts "COMMAND : #{COMMAND.options.inspect}"
    end
  end

  attr_accessor :action, :folder, :options, :params

  def initialize
    init()
  end

  def init
    self.options  = {}
    self.params   = {}
  end

end
