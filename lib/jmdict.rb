require 'nokogiri'

require 'error'
require 'constants'

module JMDict
  extend self

  def each_node(node_set, xpath)
    node_set.xpath(xpath).each do |node|
      yield(node) if block_given?
    end
  end

  def extract_from_node_set(node_set, node_name)
    raise NullNodeSet.new if node_set.nil?
    results = []
    each_node(node_set, "./#{node_name}") do |n|
      throw UnsupportedNodeError.new if n.name != node_name
      results << n.text
    end
    results.count > 0 ? results : nil
  end

  # method missing will try use #extract_from_node_set for any method that starts
  # with extract_ the remaining
  def method_missing(name, *args)
    if name.to_s.start_with? "extract_"
      return extract_from_node_set(args.first, name.to_s.gsub(/^extract_/, ''))
    end
    super(name)
  end

  # <!ELEMENT k_ele (keb, ke_inf*, ke_pri*)>
  # 	<!-- The kanji element, or in its absence, the reading element, is
  # 	the defining component of each entry.
  # 	The overwhelming majority of entries will have a single kanji
  # 	element associated with a word in Japanese. Where there are
  # 	multiple kanji elements within an entry, they will be orthographical
  # 	variants of the same word, either using variations in okurigana, or
  # 	alternative and equivalent kanji. Common "mis-spellings" may be
  # 	included, provided they are associated with appropriate information
  # 	fields. Synonyms are not included; they may be indicated in the
  # 	cross-reference field associated with the sense element.
  # 	-->
  # <!ELEMENT keb (#PCDATA)>
  # 	<!-- This element will contain a word or short phrase in Japanese
  # 	which is written using at least one non-kana character (usually kanji,
  # 	but can be other characters). The valid characters are
  # 	kanji, kana, related characters such as chouon and kurikaeshi, and
  # 	in exceptional cases, letters from other alphabets.
  # 	-->
  # <!ELEMENT ke_inf (#PCDATA)>
  # 	<!-- This is a coded information field related specifically to the
  # 	orthography of the keb, and will typically indicate some unusual
  # 	aspect, such as okurigana irregularity.
  # 	-->
  # <!ELEMENT ke_pri (#PCDATA)>
  # 	<!-- This and the equivalent re_pri field are provided to record
  # 	information about the relative priority of the entry,  and consist
  # 	of codes indicating the word appears in various references which
  # 	can be taken as an indication of the frequency with which the word
  # 	is used. This field is intended for use either by applications which
  # 	want to concentrate on entries of  a particular priority, or to
  # 	generate subset files.
  # 	The current values in this field are:
  # 	- news1/2: appears in the "wordfreq" file compiled by Alexandre Girardi
  # 	from the Mainichi Shimbun. (See the Monash ftp archive for a copy.)
  # 	Words in the first 12,000 in that file are marked "news1" and words
  # 	in the second 12,000 are marked "news2".
  # 	- ichi1/2: appears in the "Ichimango goi bunruishuu", Senmon Kyouiku
  # 	Publishing, Tokyo, 1998.  (The entries marked "ichi2" were
  # 	demoted from ichi1 because they were observed to have low
  # 	frequencies in the WWW and newspapers.)
  # 	- spec1 and spec2: a small number of words use this marker when they
  # 	are detected as being common, but are not included in other lists.
  # 	- gai1/2: common loanwords, based on the wordfreq file.
  # 	- nfxx: this is an indicator of frequency-of-use ranking in the
  # 	wordfreq file. "xx" is the number of the set of 500 words in which
  # 	the entry can be found, with "01" assigned to the first 500, "02"
  # 	to the second, and so on. (The entries with news1, ichi1, spec1, spec2
  # 	and gai1 values are marked with a "(P)" in the EDICT and EDICT2
  # 	files.)
  #
  # 	The reason both the kanji and reading elements are tagged is because
  # 	on occasions a priority is only associated with a particular
  # 	kanji/reading pair.
  # 	-->
  def extract_k_ele(node)
    results = []
    node.each do |k_ele|
      results << {
        keb: k_ele.xpath("./#{Tag::KEB}").text,
        ke_inf: extract_ke_inf(k_ele),
        ke_pri: extract_ke_pri(k_ele)
      }
    end
    results.count > 0 ? results : nil
  end

  # <!ELEMENT r_ele (reb, re_nokanji?, re_restr*, re_inf*, re_pri*)>
  # 	<!-- The reading element typically contains the valid readings
  # 	of the word(s) in the kanji element using modern kanadzukai.
  # 	Where there are multiple reading elements, they will typically be
  # 	alternative readings of the kanji element. In the absence of a
  # 	kanji element, i.e. in the case of a word or phrase written
  # 	entirely in kana, these elements will define the entry.
  # 	-->
  # <!ELEMENT reb (#PCDATA)>
  # 	<!-- this element content is restricted to kana and related
  # 	characters such as chouon and kurikaeshi. Kana usage will be
  # 	consistent between the keb and reb elements; e.g. if the keb
  # 	contains katakana, so too will the reb.
  # 	-->
  # <!ELEMENT re_nokanji (#PCDATA)>
  # 	<!-- This element, which will usually have a null value, indicates
  # 	that the reb, while associated with the keb, cannot be regarded
  # 	as a true reading of the kanji. It is typically used for words
  # 	such as foreign place names, gairaigo which can be in kanji or
  # 	katakana, etc.
  # 	-->
  # <!ELEMENT re_restr (#PCDATA)>
  # 	<!-- This element is used to indicate when the reading only applies
  # 	to a subset of the keb elements in the entry. In its absence, all
  # 	readings apply to all kanji elements. The contents of this element
  # 	must exactly match those of one of the keb elements.
  # 	-->
  # <!ELEMENT re_inf (#PCDATA)>
  # 	<!-- General coded information pertaining to the specific reading.
  # 	Typically it will be used to indicate some unusual aspect of
  # 	the reading. -->
  # <!ELEMENT re_pri (#PCDATA)>
  # 	<!-- See the comment on ke_pri above. -->
  def extract_r_ele(node)
    results = []
    node.each do |r_ele|
      results << {
        reb: r_ele.xpath("./#{Tag::REB}").text,
        re_nokanji: extract_re_nokanji(r_ele),
        re_restr: extract_re_restr(r_ele),
        re_inf: extract_re_inf(r_ele),
        re_pri: extract_re_pri(r_ele)
      }
    end
    results
  end

  # <!ELEMENT re_nokanji (#PCDATA)>
  # 	<!-- This element, which will usually have a null value, indicates
  # 	that the reb, while associated with the keb, cannot be regarded
  # 	as a true reading of the kanji. It is typically used for words
  # 	such as foreign place names, gairaigo which can be in kanji or
  # 	katakana, etc.
  # 	-->
  def extract_re_nokanji(node_set)
    result = false
    each_node(node_set, "./#{Tag::RE_NOKANJI}") do |n|
      result = true
    end
    result
  end

  # <!ELEMENT sense (stagk*, stagr*, pos*, xref*, ant*, field*, misc*, s_inf*, lsource*, dial*, gloss*)>
  # <!-- The sense element will record the translational equivalent
  # of the Japanese word, plus other related information. Where there
  # are several distinctly different meanings of the word, multiple
  # sense elements will be employed.
  # -->
  def extract_sense(node_set)
    results = []
    node_set.each do |node|
      results << {
        stagk: extract_stagk(node),
        stagr: extract_stagr(node),
        pos: extract_pos(node),
        xref: extract_xref(node),
        ant: extract_ant(node),
        field: extract_field(node),
        misc: extract_misc(node),
        s_inf: extract_s_inf(node),
        language_sources: extract_lsources(node),
        dial: extract_dial(node),
        gloss: extract_gloss(node)
      }
    end
    results.count > 0 ? results : nil
  end

  # <!ELEMENT lsource (#PCDATA)>
  # 	<!-- This element records the information about the source
  # 	language(s) of a loan-word/gairaigo. If the source language is other
  # 	than English, the language is indicated by the xml:lang attribute.
  # 	The element value (if any) is the source word or phrase.
  # 	-->
  # <!ATTLIST lsource xml:lang CDATA "eng">
  # 	<!-- The xml:lang attribute defines the language(s) from which
  # 	a loanword is drawn.  It will be coded using the three-letter language
  # 	code from the ISO 639-2 standard. When absent, the value "eng" (i.e.
  # 	English) is the default value. The bibliographic (B) codes are used. -->
  # <!ATTLIST lsource ls_type CDATA #IMPLIED>
  # 	<!-- The ls_type attribute indicates whether the lsource element
  # 	fully or partially describes the source word or phrase of the
  # 	loanword. If absent, it will have the implied value of "full".
  # 	Otherwise it will contain "part".  -->
  # <!ATTLIST lsource ls_wasei CDATA #IMPLIED>
  # 	<!-- The ls_wasei attribute indicates that the Japanese word
  # 	has been constructed from words in the source language, and
  # 	not from an actual phrase in that language. Most commonly used to
  # 	indicate "waseieigo". -->
  def extract_lsources(node)
    raise UnsupportedNodeError.new if node.nil?
    results = []
    each_node(node, "./#{Tag::LSOURCE}") do |lsource|
      results << extract_lsource(lsource)
    end
    results.count > 0 ? results : nil
  end

  def extract_lsource(lsource)
    raise UnsupportedNodeError.new(lsource.name) if lsource.name.downcase != Tag::LSOURCE
    {
      wasei: lsource[Attribute::LS_WASEI] == 'y'? 'y' : 'n',
      language: lsource[Attribute::XML_LANG] != 'eng'? lsource[Attribute::XML_LANG] : 'eng',
      type: lsource[Attribute::LS_TYPE] == 'part'? 'part' : 'full',
      source_word: lsource.text
    }
  end

  # <!ELEMENT gloss (#PCDATA | pri)*>
  # 	<!-- Within each sense will be one or more "glosses", i.e.
  # 	target-language words or phrases which are equivalents to the
  # 	Japanese word. This element would normally be present, however it
  # 	may be omitted in entries which are purely for a cross-reference.
  # 	-->
  def extract_gloss(node)
    results = []
    each_node(node, "./#{Tag::GLOSS}") do |gloss|
      results << gloss.text
    end
    results.count > 0 ? results : nil
  end

  def convert_to_json(node_set)
    results = []
    each_node(node_set, "//#{Tag::ENTRY}") do |entry|
      results << {
        ent_seq: entry.xpath("./#{Tag::ENT_SEQ}").text.to_i,
        k_ele: extract_k_ele(entry.xpath("./#{Tag::K_ELE}")),
        r_ele: extract_r_ele(entry.xpath("./#{Tag::R_ELE}")),
        sense: extract_sense(entry.xpath("./#{Tag::SENSE}"))        
      }
    end
    results
  end

  def search_files_with_index(dir)
    index = 0
    search_files(dir) do |file_name, node_set|
      yield(file_name, node_set, index) if block_given?
      index += 1
    end
  end

  def search_files(dir)
    Dir.foreach(dir) do |file_name|
      next if !file_name.end_with? ".xml"
      xml_file = File.join(dir, file_name)
      yield(xml_file, File.open(xml_file) { |f| Nokogiri::XML(f) }) if block_given?
    end
  end

end
