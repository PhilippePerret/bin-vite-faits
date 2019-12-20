# encoding: UTF-8
class Command

  class << self

    # Analyse la ligne de commande courante
    def decompose
      ARGV.each do |arg|
        if arg.start_with?('--')
          key = arg[2..-1]
          COMMAND.options.merge!(key.to_sym => true)
        elsif arg.start_with?('-')
          # Trait simple
          keys = arg[1..-1].split('')
          keys.each do |key|
            key = MIN_OPT_TO_REAL_OPT[key]
            if key.nil?
              error "L'option #{arg} est inconnue."
            else
              COMMAND.options.merge!(key.to_sym => true)
            end
          end
        elsif arg.include?('=')
          key, val = arg.split('=')
          real_key = COMMAND_OTHER_PARAM_TO_REAL_PARAM[key] || key
          COMMAND.params.merge!(real_key.to_sym => val)
        elsif COMMAND.action.nil?
          COMMAND.action = arg
        elsif COMMAND.folder.nil?
          COMMAND.folder = arg
        end
      end
      # puts "COMMAND : #{COMMAND.options.inspect}"
    end


    # Utiliser Command.clear_terminal
    def clear_terminal
      puts "\033c"
    end

  end #/<< self

  attr_accessor :action, :folder, :options, :params

  def initialize
    init()
  end

  def init
    self.options  = {}
    self.params   = {}
  end

end
