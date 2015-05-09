require 'rubygems'
require 'bundler'

Bundler.require
require 'unirest'
require 'rack/cache'
require 'restclient/components'

require './app'
run Sinatra::Application