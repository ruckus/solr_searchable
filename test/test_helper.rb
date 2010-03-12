# require 'rubygems'
# require 'active_support'
# require 'active_support/test_case'

ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'rubygems'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))
require 'active_support'
require 'active_support/test_case'
require 'test/unit'
require 'action_controller/test_process'
