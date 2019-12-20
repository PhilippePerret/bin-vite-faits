# encoding: UTF-8
=begin
  Les méthodes d'entrée/sortie utiles pour le Terminal
=end

def prompt(question)
  return IOConsole.wait_for_string(question)
end

def promptChar(question)
  return IOConsole.wait_for_char(question)
end

def yesNo(question)
  return IOConsole.yesNo(question)
end

def getChar(question)
  IOConsole.getChar(question)
end

def clear
  Command.clear_terminal
end

# Méthode qui retourne TRUE si on presse la
# barre espace ou rien dans le cas contraire,
# sauf si c'est 'q'
def SPACEOrQuit(question)
  return IOConsole.waitForSpaceOrQuit(question)
end

class IOConsole
class << self
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
    end while char != 'y' && char != 'n' && char != 'q'
    if char == 'q'
      return nil
    else
      return char == 'y'
    end
  end
  def wait_for_string question
    print "\n#{question} : "
    str = STDIN.gets
    str = str.strip
    if str == 'q' || str == ""
      return nil
    else
      str
    end
  end
  alias :prompt :wait_for_string

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
