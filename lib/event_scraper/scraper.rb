require 'singleton'
require 'yaml'

class Class
  def conf(*paths)
    class_exec(paths) do |x|
      define_method :option do |s = nil|
        @option ||= x.reverse.inject({}) do |memo, path|
          subsettings = EventScraper.get_node(eval "\"#{path}\"")
          subsettings ? memo.merge(subsettings) : memo
        end
        s ? @option[s] : @option
      end
    end
  end
end

module EventScraper

  module Scraper

    attr_accessor :events, :formatter, :active_events

    def events
      @events ||= []
    end

    def update
      events.each do |event|
        if option('events').keys.include?(event.name)
          event.update
        end
      end
    end

    def load(file = nil)
      file ||= option("database")
      @events = YAML.load_file(File.expand_path(file))
    end

    def load_and_add
      load

      active_events = option("events").keys
      all_events = events.map { |e| e.name }
      new_events = active_events - all_events
      new_events.each do |n|
        add(n)
      end
    end

    def add(event_name)
      @events << Event.new(event_name)
    end

    def save(file = nil)
      file ||= option("database")
      file = File.expand_path(file)
      File.open(file, "w") { |f| f.write(events.to_yaml) }
    end

    def active_events
      @events.select do |event|
        option("events").keys.include?(event.name)
      end
    end

    def format
      @formatter ||= EventFormatter.new
      @formatter.format(active_events)
    end

  end

end
