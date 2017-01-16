module JMDict
  class Base
    def initialize(json)
      @json = json
    end
    def get_array(attribute)
      array = get_attribute(attribute)
      array.nil?? [] : array
    end
    def get_attribute(attribute)
      @json[attribute]
    end
  end
end
