module DNSMessage
  class ResourceRecord

    attr_accessor :name, :type, :klass, :ttl, :rdata

    #def method_missing(name, *args, &block)
    #  return super(method, *args, &block) unless name.to_s =~ /^[parse|build]_\w+/
    #end

    def initialize(record, name_pointers)
      @name_pointers = name_pointers
      parse(record)
    end

    def type_str(type)
      Type::TYPE_STRINGS[type]
    end

    def parse(record)
      @name, idx = DNSMessage::Name.parse(record,@name_pointers)
      @type, @klass, @ttl, rdata_length = record[idx...idx+10].unpack("nnNn")
      @rdata = send("parse_#{type_str(@type)}", record[idx+10..-1], rdata_length)
    end

    def parse_A(rdata, _)
      IPAddr.new_ntoh(rdata)
    end

  end
end
