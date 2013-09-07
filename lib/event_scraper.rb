$: << File.dirname(__FILE__)

require 'nokogiri'
require 'optparse'
require 'logger'
require 'open-uri'
require 'cgi'

require 'event_scraper/scraper'
require 'event_scraper/cli'
require 'event_scraper/logger'
require 'event_scraper/version'
require 'event_scraper/event'

require 'event_scraper/scrapers/allocine/allocine'
require 'event_scraper/scrapers/tvrage/tvrage'

module EventScraper
  DEFAULTS = {
    "Scrapers" => [],
  }

  def self.options
    @options ||= DEFAULTS.dup
  end

  def self.options=(opts)
    @options = opts
  end

  def self.get_node(path = nil)
    names = path.split("/").delete_if(&:empty?)
    names.inject(options) do |memo, obj|
      memo = memo[obj]
    end
  end
end
