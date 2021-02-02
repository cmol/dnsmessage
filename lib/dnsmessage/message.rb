module DNSMessage
  class Message

    NAME_POINTER = 0xc0
    POINTER_MASK = 0x3fff
    QUERY        = 0
    REPLY        = 1
    HEADER_SIZE  = 12

    attr_accessor :questions, :answers, :authority, :additionals
    attr_reader :id, :qr, :opcode, :aa, :tc, :rd, :ra, :z, :rcode,
      :qdcount, :ancount, :nscount, :arcount

    def initialize()
      @questions   = []
      @answers     = []
      @additionals = []
    end

    def parse(input)
      parse_header(input)
      idx = parse_questions(input, @qdcount)
      @answers, idx     = parse_records(input, @ancount, idx)
      @authority, idx   = parse_records(input, @nscount, idx)
      @additionals, idx = parse_records(input, @arcount, idx)
    end

    def self.parse(input)
      message = self.new()
      message.parse(input)
      message
    end

    def parse_header(message)
      return nil if message.nil? || message.empty?
      @id, opts, @qdcount, @ancount, @nscount, @arcount =
        message[0...12].unpack("n6")
      @qr     = (opts >> 15) & 0x1
      @opcode = (opts >> 11) & 0xf
      @aa     = (opts >> 10) & 0x1
      @tc     = (opts >>  9) & 0x1
      @rd     = (opts >>  8) & 0x1
      @ra     = (opts >>  7) & 0x1
      @z      = (opts >>  4) & 0x7
      @rcode  =  opts        & 0xf
    end

    def parse_name(message, idx)
      # Read name loop
      name = []
      loop do
        length = message[idx].unpack("c").first
        idx += 1
        if length & NAME_POINTER == NAME_POINTER
          ptr = ((length << 8) | message[idx].unpack("c").first) & POINTER_MASK
          return [parse_name(message, ptr).first,idx+1]
        elsif length == 0
          break
        else
          name << message[idx...idx+length]
          idx += length
        end
      end
      [name.join("."), idx]
    end

    def parse_questions(message, num_questions)
      idx = HEADER_SIZE # Header takes up the first 12 bytes
      @questions = (0...num_questions).map do
        name, idx = parse_name(message, idx)

        # take last four bytes
        type, klass = message[idx..-1].unpack("n2")
        idx += 4
        [name, type, klass]
      end

      idx
    end

    def parse_records(message, num_records, idx)
      [num_records.times.map do
        name, idx = parse_name(message, idx)
        type, klass, ttl, rdata_length = message[idx...idx+10].unpack("nnNn")
        idx += 10
        rdata = message[idx...idx+rdata_length]
        idx += rdata_length
        [name, type, klass, ttl, rdata]
      end,
      idx]
    end

    def build
      name_pointers = {}
      packet  = build_header
      packet << build_questions(name_pointers, packet.size)
      packet << build_answers(name_pointers, packet.size)
      packet << build_authority(name_pointers, packet.size)
      packet << build_additionals(name_pointers,packet.size)
    end

    def build_header
      opts = (@qr     & 0x1) << 15 |
             (@opcode & 0xf) << 11 |
             (@aa     & 0x1) << 10 |
             (@tc     & 0x1) << 9  |
             (@rd     & 0x1) << 8  |
             (@ra     & 0x1) << 7  |
             (@z      & 0x7) << 4  |
             (@z      & 0xf)
      [@id, opts, @qdcount, @ancount, @nscount, @arcount].pack("n6")
    end

    def build_questions(name_pointers, idx)
      @questions.map do | name, type, klass |
        name_bytes = build_name(name,name_pointers,idx)
        name_bytes + [type,klass].pack("n2")
      end.join("")
    end

    def build_answers(name_pointers, idx)
      build_record(name_pointers, idx, @answers)
    end

    def build_authority(name_pointers, idx)
      build_record(name_pointers, idx, @authority)
    end

    def build_additionals(name_pointers, idx)
      build_record(name_pointers, idx, @additionals)
    end

    def build_record(name_pointers, idx, records)
      records.map do |name, type, klass, ttl, rdata|
        name_bytes = build_name(name,name_pointers,idx)
        name_bytes + [type, klass, ttl, rdata.length].pack("nnNn") + rdata
      end.join("")
    end

    def build_name(name, name_pointers, idx)
      if name_pointers[name]
        name_bytes = [(name_pointers[name] | NAME_POINTER << 8)].pack("n")
      else
        name_pointers[name] = idx
        name_bytes = name.split(".").map do | section |
          section.length.chr + section
        end.join("") + "\x0" # Terminate will nullptr
      end
    end

    def check_validity
      raise(StandardError, "Bad qr type") if @qr != 0
      raise(StandardError, "No questions in query") if @qdcount < 1
      raise(StandardError, "Empty domain")  if @domain_name.empty?
    end

  end
end
