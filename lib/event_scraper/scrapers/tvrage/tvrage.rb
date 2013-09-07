module EventScraper

  class TVRageOrgFormatter
    conf "TVRage/OrgFormatter"

    def format(events)
      body = events.map do |e|
        time_format = (e.option("time_format") ||
                       option("time_format") ||
                       "%Y-%m-%d %H:%M")

        template = (e.option("org_template") ||
                    option("org_template") ||
                    "*** <%U> %N S%SE%E %T")

        list = e.eps_list
        list << e.next_eps if e.next_eps

        line = list.map do |l|
          time_str = l.air_date.strftime(time_format)
          template.gsub("%N", e.alt_name || e.name)
            .gsub("%U", time_str)
            .gsub("%T", l.title)
            .gsub("%S", "%02d" % l.season)
            .gsub("%E", "%02d" % l.episode)
        end.join("\n")

        head = e.option("head") || option("sub_head") || "** %N"
        head = head.sub("%N", e.alt_name || e.name)
        head ? head + "\n" + line : line
      end.join("\n")

      if option("head")
        option("head") + "\n" + body
      else
        body
      end
    end
  end

  class TVRageScraper
    conf "TVRage/Scraper"

    include Scraper

    def add(event_name)
      @events << TVRageEvent.new(event_name)
    end

    def format
      EventScraper.const_get(option("formatter")).new.format(active_events)
    end

  end

  class Episode
    attr_accessor :title, :air_date, :season, :episode
  end

  class InvalidEpisode < StandardError
  end

  class TVRageEvent < Event

    conf 'TVRage/Scraper/events/#{name}', 'TVRage/Event'

    BASE_URL="http://services.tvrage.com/feeds/search.php?show=%s"
    SEARCH_URL="http://services.tvrage.com/feeds/episodeinfo.php?sid=%d"

    attr_accessor :name, :alt_name, :id, :next_eps, :eps_list, :last_check

    def initialize(name)
      @name = name
      @eps_list = []
      @id = nil
      @last_check = nil
    end

    # Update next air date if needed. Depends on last check and next air
    # date if any.
    def update
      Logging.logger.debug("Update next episode for show #{@name}")
      Logging.logger.debug("Last check date is #{@last_check || "nil"}")

      now = DateTime.now
      Logging.logger.debug("Now is #{now}")

      if @next_eps
        Logging.logger.debug("Next episode present")
        if @next_eps.air_date < now
          Logging.logger.debug("Next episode is past")
          @eps_list << @next_eps
          @last_check = now
          begin
            eps = retrieve_next_episode
            @next_eps = eps
          rescue InvalidEpisode => e
            Logging.logger.error(e.message)
            @next_eps = nil
          end
        else
          if @last_check and @next_eps.air_date - now < now - @last_check \
            and @next_eps.air_date > now + option("days_preceding")
            Logging.logger.debug("Mid date reached or not too close to next air date")
            begin
              @last_check = now
              @next_eps = retrieve_next_episode
            rescue InvalidEpisode => e
              Logging.logger.error(e.message)
            end
          else
            Logging.logger.debug("Not at mid date or show in less than %d days" %
                       option("days_preceding"))
          end
        end
      else
        Logging.logger.debug("No next episode")
        if not @last_check or now - @last_check > option("days_until_next_check")
          Logging.logger.debug("More than #{option("days_until_next_check")} days since last check or no last check")
          begin
            @last_check = now
            @next_eps = retrieve_next_episode
          rescue InvalidEpisode => e
            Logging.logger.error(e.message)
          end
        else
          Logging.logger.debug("No need to check again")
        end
      end
    end

    private

    def retrieve_next_episode
      Logging.logger.debug("Retrieving next \"#{name}\" episode data")

      unless @id
        Logging.logger.debug("No ID, retrieving...")
        begin
          doc = Nokogiri::XML(open(BASE_URL % CGI::escape(name)))
          @id = doc.xpath("/Results/show[1]/showid").text.to_i
        rescue Exception => e
          puts e
          raise InvalidEpisode.new("Unable to retrieve id")
        end
      end

      Logging.logger.debug("Id is #{@id}")
      eps = Episode.new

      begin
        doc = Nokogiri::XML(open(SEARCH_URL % @id))
        sec = doc.xpath("/show/nextepisode/airtime[@format='GMT+0 NODST']").text.to_i
      rescue
        raise InvalidEpisode.new("Unable to parse date")
      end

      eps.air_date = Time.at(sec).to_datetime

      Logging.logger.debug("Air date is #{eps.air_date || "nil"}")
      if eps.air_date.nil? or eps.air_date < DateTime.now
        raise InvalidEpisode.new("Invalid date")
      end

      begin
        eps.title = doc.xpath("/show/nextepisode/title").text
      rescue
        raise InvalidEpisode.new("Unable to parse title")
      end

      Logging.logger.debug("Title is \"#{eps.title || "nil"}\"")

      begin
        number = doc.xpath("/show/nextepisode/number").text
      rescue
        raise InvalidEpisode.new("Unable to parse episode number")
      end

      if number =~ /(\d+)x(\d+)/
        eps.season = $1.to_i
        eps.episode = $2.to_i
      else
        raise InvalidEpisode.new("Invalid episode number")
      end
      Logging.logger.debug("Season is #{eps.season}")
      Logging.logger.debug("Episode is #{eps.episode}")

      eps
    end
  end
end
