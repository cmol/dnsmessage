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
      @authority   = []
    end

    def parse(input)
      pointer = Pointer.new()
      parse_header(input)
      idx = parse_questions(input, @qdcount, pointer)
      @answers, idx     = parse_records(input, @ancount, idx, pointer)
      @authority, idx   = parse_records(input, @nscount, idx, pointer)
      @additionals, idx = parse_records(input, @arcount, idx, pointer)
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

    def parse_questions(message, num_questions, pointer)
      idx = HEADER_SIZE # Header takes up the first 12 bytes
      @questions = (0...num_questions).map do
        name, size, ptr = Name.parse(message[idx..-1], pointer)
        pointer.add(idx, name) if ptr
        idx += size

        # take last four bytes
        type, klass = message[idx..-1].unpack("n2")
        idx += 4
        [name, type, klass]
      end

      idx
    end

    def parse_records(message, num_records, idx, pointer)
      [num_records.times.map do
        ResourceRecord.parse(message[idx..-1],pointer).tap do | rr |
          pointer.add_arr(rr.add_to_hash,idx)
          idx += rr.size
        end
      end,
      idx]
    end

    def build
      pointer = Pointer.new()
      packet  = build_header
      packet << build_questions(pointer, packet.size)
      packet << build_answers(pointer, packet.size)
      packet << build_authority(pointer, packet.size)
      packet << build_additionals(pointer,packet.size)
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
      [@id, opts,
       @questions.length,
       @answers.length,
       @authority.length,
       @additionals.length].pack("n6")
    end

    def build_questions(pointer, idx)
      @questions.map do | name, type, klass |
        name_bytes, add_to_hash = Name.build(name,pointer)
        pointer.add(name, idx) if add_to_hash
        name_bytes + [type,klass].pack("n2")
      end.join("")
    end

    def build_answers(pointer, idx)
      build_record(pointer, idx, @answers)
    end

    def build_authority(pointer, idx)
      build_record(pointer, idx, @authority)
    end

    def build_additionals(pointer, idx)
      build_record(pointer, idx, @additionals)
    end

    def build_record(pointer, idx, records)
      records.map do | rr |
        rr.build(pointer,idx).tap do | r |
          idx += r.length
        end
      end.join("")
    end

    def check_validity
      raise(StandardError, "Bad qr type") if @qr != 0
      raise(StandardError, "No questions in query") if @qdcount < 1
      raise(StandardError, "Empty domain")  if @domain_name.empty?
    end

  end
end
