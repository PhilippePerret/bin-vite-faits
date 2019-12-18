# encoding: UTF-8
require 'fileutils'
require 'json'

THISFOLDER = File.expand_path(File.dirname(__FILE__))

Dir["#{THISFOLDER}/required/*.rb"].each{|m| require m}

COMMAND = Command.new()
