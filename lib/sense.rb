module JMDict
  class Sense < Base
    def initialize(json)
      super(json)
      @language_sources = generate_language_sources
    end

    def generate_language_sources
      lsources = []
      # only do this if there are actually language sources.
      @json[:language_sources].each do |lsource|
        lsources << LanguageSource.new(lsource)
      end unless @json[:language_sources].nil?
      lsources
    end

    def glossary
      @glossary ||= build_glossary
    end

    def parts_of_speech
      @pos ||= get_array(:pos)
    end

    def misc
      @misc ||= get_array(:misc)
    end

    def dialects
      @dialects ||= get_array(:dial)
    end

    def stagk
      @stagk ||= get_array(:stagk)
    end

    def stagr
      @stagr ||= get_array(:stagr)
    end

    def cross_references
      @xref ||= get_array(:xref)
    end

    def antonyms
      @anytonym ||= get_array(:ant)
    end

    def fields
      @field ||= get_array(:field)
    end

    def information
      @s_inf ||= get_array(:s_inf)
    end

    private

    def build_glossary
      glossary = []
      get_array(:gloss).each do |glossary_term|
        glossary << Gloss.new(glossary_term)
      end
      glossary
    end
  end
end
