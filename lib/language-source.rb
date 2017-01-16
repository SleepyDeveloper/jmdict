module JMDict
  class LanguageSource < Base
    def wasei
      @wasei ||= get_attribute(:wasei) == 'n'? false : true
    end

    def language
      @language ||= get_attribute(:lanaguage)
    end

    def type
      @type ||= get_attribute(:type)
    end

    def source_word
      @source_word ||= get_attribute(:source_word)
    end
  end
end
