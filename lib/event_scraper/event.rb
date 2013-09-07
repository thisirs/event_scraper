module EventScraper

  class Event
    attr_accessor :name

    # Exclude options from YAML serialization
    def encode_with(coder)
      self.instance_variables.each do |var|
        unless var == :@options
          coder[var.to_s.sub('@', '')] = instance_variable_get(var)
        end
      end
    end

    def initialize(name)
      @name = name
    end

    def format

    end
  end
end
