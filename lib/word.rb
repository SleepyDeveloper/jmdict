module JMDict
  class Word < Base
    attr_accessor :ent_seq, :main, :senses
    def initialize(json)
      super(json)
      @ent_seq = json[:ent_seq]
      @readings = kanji_and_pronounciation(json[:k_ele], json[:r_ele])
      @senses = get_senses(json[:sense])
    end

    def readings(**options)
      if options[:include_main]
        [@main] + @readings
      else
        @readings
      end
    end

    private

    def get_senses(senses)
      sense_list = []
      senses.each do |sense|
        sense_list << Sense.new(sense)
      end
      sense_list
    end

    def kanji_and_pronounciation(k_ele, r_ele)
      readings, no_kanji = split_readings(r_ele, k_ele.nil?)

      results = []
      k_ele.each do |kanji|
        temp = default_reading.merge({ kanji: kanji[:keb] })
        temp[:information] += kanji[:ke_inf].flatten unless kanji[:ke_inf].nil?
        temp[:priorities] += kanji[:ke_pri].flatten unless kanji[:ke_pri].nil?
        readings.each do |reading|
          temp[:readings] << reading[:reb] if reading_applies?(kanji[:keb], reading[:re_restr])
        end
        results << temp
      end unless k_ele.nil?
      results += filter_no_kanji(no_kanji)
      @main = results.shift
      results
    end

    def filter_no_kanji(no_kanj)
      no_kanj.map{ |n| default_reading.merge(
        {
          kanji: nil,
          readings: [n[:reb]],
          information: n[:re_inf],
          priorities: n[:re_pri]
        }.reject{|key,value| value.nil? })
      }
    end

    def default_reading
      {
        kanji: nil,
        readings: [],
        information: [],
        priorities: []
      }
    end

    def split_readings(r_ele, k_ele_is_nil)
      readings = []
      no_kanji = []
      r_ele.each do |reading|
        if reading[:re_nokanji] || k_ele_is_nil
          no_kanji << reading
        else
          readings << reading
        end
      end
      return readings, no_kanji
    end

    def reading_applies?(kanji, restriction)
      if restriction.nil?
        true
      else
        restriction.include? kanji
      end
    end
  end
end
