module DNSMessage
  class ResourceRecord

    PARSERS = {
      Type::A     => :parse_ip,
      Type::AAAA  => :parse_ip,
      Type::CNAME => :parse_name,
      Type::OPT   => :parse_opt,
      Type::TXT   => :parse_text
    }

    BUILDERS = {
      Type::A     => :build_ip,
      Type::AAAA  => :build_ip,
      Type::CNAME => :build_name,
      Type::OPT   => :build_opt,
      Type::TXT   => :build_text
    }

    attr_accessor :name, :type, :klass, :ttl, :rdata,
      :opt_udp, :opt_rcode, :opt_edns0_version, :opt_z_dnssec
    attr_reader :size, :add_to_hash

    def initialize(name: nil, type: nil, klass: Class::IN, ttl: 0,
                   rdata: nil)
      @name  = name
      @type  = type
      @klass = klass
      @ttl   = ttl
      @rdata = rdata
      @add_to_hash = []
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
      @rdata = send(parser(@type), record, idx+10, rdata_length, ptr)
      @size = idx + 10 + rdata_length
    end

    def build(ptr,idx)
      return "" unless BUILDERS[type]

      name_bytes, add = Name.build(@name, ptr)
      ptr.add(@name, idx) if add
      data = send(builder(@type),ptr, idx + name_bytes.length)
      @rdata_length = data.length
      name_bytes + [@type, @klass, @ttl, @rdata_length].pack("nnNn") + data
    end

    def self.default_opt(size)
      self.new().tap do | opt |
        opt.name = ""
        opt.type = Type::OPT
        opt.opt_udp = size
        opt.opt_rcode = 0
        opt.opt_edns0_version = 0
        opt.opt_z_dnssec = 0
      end
    end

    private

    def parser(type)
      PARSERS[type]
    end

    def builder(type)
      BUILDERS[type]
    end

    ##
    ## Parsers
    ##

    def parse_ip(rdata, start, length, ptr)
      IPAddr.new_ntoh(rdata[start...start+length])
    end

    def parse_opt(rdata, start, length, ptr)
      @opt_udp           = @klass
      @opt_rcode, @opt_edns0_version, @opt_z_dnssec =
        [@ttl].pack("N").unpack("CCn")
      @opt_z_dnssec = @opt_z_dnssec >> 15
    end

    def parse_text(rdata, start, length, ptr)
      txt_length = rdata[start].ord
      rdata[start+1..start+txt_length]
    end

    def parse_name(rdata, start, length, ptr)
      name, idx, add = Name.parse(rdata[0...length], ptr)
      @add_to_hash << [start+idx, name] if add
      name
    end

    ##
    ## Builders
    ##

    def build_ip(ptr, _)
      @rdata.hton
    end

    def build_opt(ptr, _)
      @klass = @opt_udp
      @ttl = [@opt_rcode,
              @opt_edns0_version,
              @opt_z_dnssec << 15].pack("CCn").unpack("N").first
      "" # Set RDATA to nothing
    end

    def build_text(ptr, _)
      @rdata.length.chr + rdata
    end

    def build_name(ptr, idx)
      Name.build(@rdata, ptr).tap do | bytes, add |
        ptr.add(@rdata,idx) if add
        return bytes
      end
    end

  end

  # Add "alias"
  RR = ResourceRecord
end
