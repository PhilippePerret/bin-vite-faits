# encoding: UTF-8
=begin

  Les erreurs qu'on peut rencontrer
=end

# Pour des erreurs non fatale
class NonFatalError < StandardError; end
# Pour des erreurs fatales
class FatalError < StandardError; end

# Utiliser pour interrompre une création, comme avec l'assistant
class NotAnError < StandardError

  def puts_error_if_message
    if self.message && self.message != '' && self.message != 'NotAnError'
      error self.message
    end
    return false
  end

end
