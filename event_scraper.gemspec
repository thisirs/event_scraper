require File.expand_path('lib/event_scraper/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'event_scraper'
  s.version     = EventScraper::VERSION
  s.date        = '2013-09-07'
  s.description = s.summary = "A simple hello world gem"
  s.authors     = ["Sylvain Rousseau"]
  s.email       = 'thisirs@gmail.com'
  s.files       = ["lib/blah.rb"]
  s.license     = "GPL-3.0"
  s.executables = ["event_scraper"]

  s.add_dependency('nokogiri')

end
