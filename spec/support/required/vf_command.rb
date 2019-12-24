#!/usr/bin/env ruby
# encoding: UTF-8
=begin
  Class VFCommand et MyPTY
  qui permettent simplifier les tests d'application en ligne de commande

  On crée une nouvelle commande (*) (pour un test) à l'aide de :

      cmd = VFCommand.new("<ma commande> <mes options> <mes paramètres>")

  (*) quand je parle de "commande", ici, il ne s'agit pas de l'application,
      définie par VF_COMMAND, mais de ses premiers paramètres avec, souvent
      le premier qui peut être une *commande* envoyée à l'application.
      "params" serait donc peut-être un meilleur terme que "commande".

  Ensuite, pour la tester, on fait

      cmd.test do |pty|
        ... code de test
      end

  'pty' n'est pas un PTY.spawn mais permet d'interagir de la même manière,
  en utilisant `pty.gets` pour obtenir la dernière ligne écrite, ou
  `pty.puts` pour écrire quelque chose dans la pseudo-console.
  La différence est que ce 'puts' (on peut aussi utiliser 'tape' si l'on veut
  marquer la différence avec le PTY.spawn#puts) va attendre un dixième de
  seconde puis lire tout de suite la ligne en console. Donc on ne sera pas
  obligés de taper :
    foo.puts "mon texte"
    sleep 0.1
    foo.gets # pour récupérer "mon texte" echoé par la console.

  On peut obtenir tout le texte renvoyé par la console grâce à :

    pty.output

  Par exemple :

      cmd.test do |pty|
        expect(pty.output).to include("Mon texte inclus")
      end

  Noter que ce 'output' contient absolument toutes les lignes renvoyées
  en console depuis le dernier appel.

  Pour un test encore plus rapide, on peut utiliser :

      cmd = VFCommand.new('list')
      expect(cmd.output).to include("mon texte")

=end
require 'pty'


class VFCommand
  attr_reader :params
  def initialize params
    @params = params # par exemple 'assistant'
  end
  def test &block
    pty = nil
    PTY.spawn(" #{VF_COMMAND} #{params}") do |stdout, stdin, pid|
      pty = MyPTY.new(stdout, stdin, pid)
      yield pty if block_given?
    end
    return pty
  end
  alias :run :test

  # Raccourci pour obtenir la sortie de la commande
  def output
    test.output
  end
end #/MyCommand

class MyPTY
  attr_reader :stdout, :stdin, :pid
  def initialize stdout, stdin, pid
    @stdout = stdout
    @stdin  = stdin
    @pid    = pid
  end
  def tape str
    stdin.puts str
    sleep 0.1
    stdout.gets
  end
  alias :puts :tape

  # Retourne toutes les lignes de sortie
  def output
    lines = []
    while line = stdout.gets
      lines << line
    end
    lines.join()
  end
end
