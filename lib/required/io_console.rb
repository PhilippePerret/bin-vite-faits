# encoding: UTF-8
=begin
  Les méthodes d'entrée/sortie utiles pour le Terminal
=end

# Pour mettre le focus à la fenêtre Terminal
def activate_terminal
  `open -a Terminal`
  `open -a Terminal`
  `open -a Terminal`
end

def promptBlink(amorce, question)
  return IOConsole.wait_for_string_with_blink_double_message(amorce, question)
end
def prompt(question)
  return IOConsole.wait_for_string(question)
end

def promptChar(question)
  return IOConsole.wait_for_char(question)
end

def yesNo(question)
  return IOConsole.yesNo(question)
end

# Pour poser une question et produire une erreur en cas d'autre réponse
# que 'y'
# Pour fonctionner, la méthode (ou la sous-méthode) qui utilise cette
# formule doit se terminer par :
#     rescue NotAnError => e
#       e.puts_error_if_message
#     end
def yesOrStop(question)
  yesNo(question) || raise(NotAnError.new)
end


def getChar(question)
  IOConsole.getChar(question)
end

def clear
  puts "\n\n" # pour certaines méthodes
  puts "\033c"
end

# Méthode qui retourne TRUE si on presse la
# barre espace ou rien dans le cas contraire,
# sauf si c'est 'q'
def SPACEOrQuit(question)
  return IOConsole.waitForSpaceOrQuit(question)
end

class IOConsole
class << self
  def reset
    @width = nil
  end
  def getChar(question = nil)
    print "#{question} " if question
    old_state = `stty -g`
    system "stty raw -echo"
    char = STDIN.getc.chr
    # puts "Caractère pressé : '#{char}'"
    print "\r\n"
    return char
  ensure
    system "stty #{old_state}"
  end

  # Retourne la largeur de la console actuelle en nombre de caractère
  def width
    @width ||= `tput cols`.to_i
  end

  def waitForSpaceOrQuit(question)
    print "\n#{question} (SPACE ou 'q' pour quitter) "
    begin
      char = getChar
    end while char != 'q' && char != ' '
    if char == 'q'
      return nil
    else
      return true
    end
  end

  def yesNo(question)
    print "\n#{question} (y/n/q) "
    begin
      char = getChar
      char = 'y' if char == 'o'
    end while char != 'y' && char != 'n' && char != 'q'
    if char == 'q'
      return nil
    else
      return char == 'y'
    end
  end
  def wait_for_string question
    print "#{question} : "
    str = STDIN.gets
    str = str.strip
    if str == 'q' || str == ""
      return nil
    else
      str
    end
  end
  alias :prompt :wait_for_string

  # Méthode complexe qui affiche +amorce+ en clignotant, avant
  # de placer la +question+ et d'attendre un texte
  def wait_for_string_with_blink_double_message(amorce, question, options = {})
    blank_question = " " * (question.length + 1)
    blank_amorce = " " * (amorce.length)
    puts "\e[?25l"
    4.times do |i|
      print "\033[42;7m #{blank_amorce} \033[0m\r"
      sleep 0.11
      print "\033[42;7m #{amorce} \033[0m\r"
      sleep 0.11
    end
    print "\033[42;7m #{question} \033[0m"
    print "\e[?25h"
    wait_for_string('')
  end

  def wait_for_char question
    print "\n#{question}"
    char = getChar
    if char == 'q'
      return nil
    else
      char
    end
  end

end #/<< self
end #/IOConsole
