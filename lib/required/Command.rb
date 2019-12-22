# encoding: UTF-8
=begin

  Une ligne est décomposée de cette manière :

  > application [arg1] [arg2] [argN] [param1=v1] [param2=v2] [-opt] [--option]

  On trouve les arguments dans    COMMAND.args
  On trouve les paramètres dans   COMMAND.params
  On trouve les options dans      COMMAND.options
=end
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
        else
          COMMAND.args << arg
        end
      end
      if self.respond_to?(:after_decompose)
        after_decompose
      end
      # puts "COMMAND : #{COMMAND.options.inspect}"
    end

    # Utiliser Command.clear_terminal
    def clear_terminal
      puts "\033c"
    end

  end #/<< self

  attr_accessor :options, :params, :args

  def initialize
    init()
  end

  def init
    self.args     = []
    self.options  = {}
    self.params   = {}
  end

end
