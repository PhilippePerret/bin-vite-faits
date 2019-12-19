# encoding: UTF-8
require 'fileutils'
require 'json'
require 'clipboard'
require 'yaml'

THISFOLDER = File.expand_path(File.dirname(__FILE__))

Dir["#{THISFOLDER}/required/*.rb"].each{|m| require m}

COMMAND = Command.new()
