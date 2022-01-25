require 'json'

event = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))

puts event.inspect
