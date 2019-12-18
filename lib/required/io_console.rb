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

class IOConsole
class << self
  def getChar
    old_state = `stty -g`
    system "stty raw -echo"
    char = STDIN.getc.chr
    # puts "Caractère pressé : '#{char}'"
    print "\r\n"
    return char
  ensure
    system "stty #{old_state}"
  end

  def yesNo(question)
    print "\n#{question} (y/n/q) : "
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
