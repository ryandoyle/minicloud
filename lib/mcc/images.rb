module MCC
  class Images

    include Enumerable

    def all
      template_directory = `grep -e "^TEMPLATE" /etc/vz/vz.conf`.split("=")[1].strip
      `ls #{template_directory}/cache`.each_line.collect do |template|
        template.chomp.gsub(/\.tar\.gz/, '')
      end
    end

    def each(&block)
      all.each(&block)
    end

  end
end
