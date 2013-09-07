require 'logger'

module EventScraper
  module Logging
    def logger
      EventScraper::Logging.logger
    end

    def self.logger
      @logger || initialize_logger
    end

    def self.initialize_logger(log_target = STDOUT)
      @logger = Logger.new(log_target)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}: #{msg}\n"
      end
      @logger
    end
  end
end
