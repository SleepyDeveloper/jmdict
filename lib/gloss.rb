module JMDict
  class Gloss < Base
    attr_accessor :definition
    def initialize(definition)
      @definition = definition
    end
    def to_s
      @definition
    end
  end
end
