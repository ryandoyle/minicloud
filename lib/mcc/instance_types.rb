module MCC
  class InstanceTypes

    include Enumerable

    def all
      `ls /etc/vz/conf/ | grep -e "sample$"`.each_line.collect do |type|
        type.gsub(/\.conf-sample$/, '').gsub(/^ve-/, '').strip
      end
    end

    def each(&block)
      all.each(&block)
    end


  end
end
