module DNSMessage
  class ResourceRecord

    attr_accessor :name, :type, :klass, :ttl, :rdata
    attr_reader :size, :add_to_hash

    #def method_missing(name, *args, &block)
    #  return super(method, *args, &block) unless name.to_s =~ /^[parse|build]_\w+/
    #end

    def initialize(name: nil, type: nil, klass: Class::IN, ttl: 0,
                   rdata: nil)
      @name  = name
      @type  = type
      @klass = klass
      @ttl   = ttl
      @rdata = rdata
      @add_to_hash = []
    end

    def type_str(type)
      Type::TYPE_STRINGS[type]
    end

    def add_to_hash
      @add_to_hash
    end

    def self.parse(record, ptr)
      self.new().tap do |rr|
        rr.parse(record, ptr)
      end
    end

    def parse(record, ptr)
      @name, idx, add = Name.parse(record,ptr)
      @add_to_hash << [idx, @name] if add
      @type, @klass, @ttl, rdata_length = record[idx...idx+10].unpack("nnNn")
      @rdata = send("parse_#{type_str(@type)}", record, idx+10, rdata_length, ptr)
      @size = idx + 10 + rdata_length
    end

    def build(ptr,idx)
      return "" unless self.respond_to?("build_#{type_str(@type)}")
      name_bytes, add = Name.build(@name, ptr)
      ptr.add(@name, idx) if add
      data = send("build_#{type_str(@type)}",ptr)
      @rdata_length = data.length
      name_bytes + [@type, @klass, @ttl, @rdata_length].pack("nnNn") + data
    end

    ##
    ## Parsers
    ##

    def parse_A(rdata, start, length, ptr)
      IPAddr.new_ntoh(rdata[start...start+length])
    end

    def parse_OPT(rdata, start, length, ptr)
    end

    def parse_TXT(rdata, start, length, ptr)
      txt_length = rdata[start].ord
      rdata[start+1..start+txt_length]
    end

    def parse_CNAME(rdata, start, length, ptr)
      name, idx, add = Name.parse(rdata[0...length], ptr)
      @add_to_hash << [start+idx, name] if add
      name
    end

    ##
    ## Builders
    ##

    def build_A(ptr)
      @rdata.hton
    end

    def build_OPT(ptr)
      ""
    end

    def build_TXT(ptr)
      @rdata.length.chr + rdata
    end

    def build_CNAME(ptr)
      # TODO add name to ptr
      Name.build(@rdata, ptr)[0]
    end

  end
end
