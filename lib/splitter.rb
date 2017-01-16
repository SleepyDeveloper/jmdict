module JMDict

  def split(**options)
    options = default_options.merge(options.reject{ |k,v| v.nil? })

    Splitter.split(options)
  end

  def default_options
  {
    entries_per_file: 1000
  }
  end

  module Splitter
    extend self

    def split(**options)
      raise MissingParameterError.new("output_folder") if options[:output_folder].nil?
      raise MissingParameterError.new("file") if options[:file].nil?

      $HEADER ||= load_header

      extract_entries(options[:file], options[:output_folder], options[:entries_per_file])
    end

    private

    def extract_entries(jmdict_file, output_folder, entries_per_file)
      file = File.open jmdict_file, "r"

      file_body = ""
      entries = 0
      file_number = 0
      found_entry = false

      file.each_line do |line|

        if line =~ /<entry>/
          found_entry = true
        elsif line =~ /<\/entry>/
          entries+= 1
        end

        file_body+= line if found_entry

        if entries >= entries_per_file
          create_file(output_folder, file_number, file_body)

          found_entry = false
          file_body = ""
          file_number+= 1
          entries = 0
        end
      end

      if entries > 0
        create_file(output_folder, file_number, file_body)
      end
    ensure
      file.close
    end


    def create_file(output_folder, name, body)
      File.open(File.join(output_folder, ("jmdict_%03d.xml" % name)), "w") { | f | f.write(
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
#{$HEADER}
<JMdict>
  #{body}
</JMdict>")}
    end

    def load_header
      misc = File.expand_path('../../misc', __FILE__)
      File.read("#{misc}/.jmdict_header")
    end
  end
end
