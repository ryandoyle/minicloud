module MCC
  class Instance
    def initialize(container_id)
      # :id => e[0], :ip => e[1], :status => e[2],:ostemplate => e[3],:name => e[4]}
      @container_id = container_id
    end

    attr_reader :container_id

    def running?
      status.eql? :running
    end

    def status
      vzlist('status').to_sym
    end

    def ip
      vzlist('ip')
    end

    def template
      vzlist('ostemplate')
    end

    def name
      vzlist('name')
    end

    def to_h
      { :id => @container_id, :ip => ip, :status => status,:ostemplate => template,:name => name }
    end

    private

    def vzlist(filter)
      `vzlist -a -H -o #{filter} #{@container_id}`.strip
    end

  end
end