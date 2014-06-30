require 'mcc/instance'

module MCC
  class Instances

    include Enumerable

    def all
      `vzlist -a -H -o ctid`.each_line.collect do |ctid|
        MCC::Instance.new(ctid.strip)
      end
    end

    def each(&block)
      all.each(&block)
    end

    def running
      select { |instance| instance.running? }
    end

  end
end
