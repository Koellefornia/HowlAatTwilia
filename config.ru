require 'rubygems'
require 'bundler'

Bundler.require

require 'rack/cache'
require 'restclient/components'
require 'unirest'
require './app'
run Sinatra::Application


