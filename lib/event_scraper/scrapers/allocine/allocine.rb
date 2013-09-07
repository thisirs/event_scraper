require '/home/sylvain/repositories/allocine/lib/allocine_parser'

module EventScraper

  class AllocineOrgFormatter

    conf "Allocine/OrgFormatter"

    def format(events)
      body = events.map do |e|
        time_format = (e.option("time_format") ||
                       option("time_format") ||
                       "%Y-%m-%d %H:%M")
        time_str = e.release_date.strftime(time_format)

        template = (e.option("org_template") ||
                    option("org_template") ||
                    "** %N <%U>")
        template.gsub("%N", e.name)
          .gsub("%U", time_str)
      end.join("\n")

      if option("head")
        option("head") + "\n" + body
      else
        body
      end
    end
  end

  class AllocineScraper

    include Scraper
    conf "Allocine/Scraper"

    def format
      EventScraper.const_get(option("formatter")).new.format(events)
    end

    def add(event_name)
      @events << AllocineEvent.new(event_name)
    end

  end

  class AllocineEvent < Event
    conf "Allocine/Event"

    attr_accessor :name, :id, :last_check, :release_date

    def initialize(name)
      @name = name
      @id = nil
      @last_check = nil
      @release_date = nil
    end

    def id
      @id ||= Allocine::Search.new(name).movies.first.id
    end

    def update
      if needs_update?
        date = Allocine::Movie.new(id).release_date
        @release_date = DateTime.parse(date)
        @last_check = DateTime.now
      end
    end

    def needs_update?
      now = DateTime.now

      # Already released?
      return false if release_date and release_date < now

      # Not yet updated
      return true unless last_check

      # Update every "days_until_next_check" if no release
      if release_date
        return (release_date - now < now - last_check \
                and release_date > now + option("days_preceding"))
      else
        return now - last_check > option("days_until_next_check")
      end
    end
  end
end
