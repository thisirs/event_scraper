require 'yaml'
require 'singleton'
require 'optparse'
require 'erb'
require 'logger'

module EventScraper
  class CLI
    include Singleton

    def options
      EventScraper.options
    end

    def parse(args=ARGV)
      setup_options(args)
      initialize_logger
    end

    def setup_options(args)
      cli = parse_options(args)
      cfile = cli[:conf_file] || "~/.config/event_scraper/config.yaml"

      config = parse_config(cfile)
      options.merge!(config.merge(cli))
    end

    def parse_options(argv)
      opts = {}

      parser = OptionParser.new do |o|
        o.banner = "Usage: event_scraper [OPTIONS]"

        o.on("-f", "--config CONFIG-FILE", "YAML configuration file") do |f|
          opts[:conf_file] = File.expand_path(f)
        end

        o.on("-o", "--output-file OUTPUT-FILE", "Output file") do |f|
          opts[:output_file] = File.expand_path(f)
        end

        o.on("-l", "--log-file LOG-FILE", "Log file") do |f|
          opts[:log_file] = File.expand_path(f)
        end

        o.on "-v", "--verbose", "Print more verbose output" do |arg|
          opts[:verbose] = arg
        end

        o.on '-V', '--version', "Print version and exit" do |arg|
          puts "EventScraper #{EventScraper::VERSION}"
          exit(0)
        end

        o.on( '-h', '--help', 'Display this screen' ) do
          puts o
          exit
        end
      end

      parser.parse!(argv)
      opts
    end

    def parse_config(cfile)
      opts = {}
      cfile = File.expand_path(cfile)
      if File.exist?(cfile)
        opts = YAML.load_file(cfile)
      end
      opts
    end

    def initialize_logger
      Logging.initialize_logger(options[:log_file]) if options[:log_file]
      Logging.logger.level = Logger::DEBUG if options[:verbose]
    end

    def run
      scrapers_name = options["Scrapers"]

      scrapers = scrapers_name.map { |s| EventScraper.const_get(s).new }

      scrapers.each do |s|
        s.load_and_add
        s.update
        s.save
      end

      output =
        if options[:output_file]
          File.open(options[:output_file], "w")
        else
          STDOUT
        end

      Logging.logger.info("Event data will be written on #{output.inspect.chop}")

      contents = scrapers.map { |s| s.format }.join("\n")

      output.puts(contents)
    end
  end
end
