module DNSMessage
  class ResourceRecord

    attr_accessor :name, :type, :klass, :ttl, :rdata
    attr_reader :size, :add_to_hash

    #def method_missing(name, *args, &block)
    #  return super(method, *args, &block) unless name.to_s =~ /^[parse|build]_\w+/
    #end

    def initialize(name: nil, type: nil, klass: DNSMessage::Class::IN, ttl: 0,
                   rdata: nil)
      @name  = name
      @type  = type
      @klass = klass
      @ttl   = ttl
      @rdata = rdata
    end

    def type_str(type)
      Type::TYPE_STRINGS[type]
    end

    def add_to_hash?
      @add_to_hash
    end

    def self.parse(record, ptr)
      self.new().tap do |rr|
        rr.parse(record, ptr)
      end
    end

    def parse(record, ptr)
      @name, idx, @add_to_hash = DNSMessage::Name.parse(record,ptr)
      @type, @klass, @ttl, rdata_length = record[idx...idx+10].unpack("nnNn")
      @rdata = send("parse_#{type_str(@type)}", record[idx+10..-1], rdata_length)
      @size = idx + 10 + rdata_length
    end

    def build(ptr,idx)
      return "" unless self.respond_to?("build_#{type_str(@type)}")
      name_bytes, add = DNSMessage::Name.build(@name, ptr)
      ptr.add(@name, idx) if add
      data = send("build_#{type_str(@type)}")
      @rdata_length = data.length
      name_bytes + [@type, @klass, @ttl, @rdata_length].pack("nnNn") + data
    end

    ##
    ## Parsers
    ##

    def parse_A(rdata, length)
      IPAddr.new_ntoh(rdata[0...length])
    end

    def parse_OPT(rdata, length)
    end

    def parse_TXT(rdata, length)
      txt_length = rdata[0].ord
      rdata[1..txt_length]
    end

    def parse_CNAME(rdata,length)
      name, idx, add = DNSMessage::Name.parse(rdata[0...length], name_pointers)
      name_pointers[]
    end

    ##
    ## Builders
    ##

    def build_A
      @rdata.hton
    end

    def build_OPT
      ""
    end

    def build_TXT
      @rdata.length.chr + rdata
    end

  end
end
