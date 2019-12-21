# encoding: UTF-8
=begin

  Les erreurs qu'on peut rencontrer
=end

# Utiliser pour interrompre une création, comme avec l'assistant
class NotAnError < StandardError

  def puts_error_if_message
    if self.message && self.message != '' && self.message != 'NotAnError'
      error self.message
    end
    return false
  end
  
end
