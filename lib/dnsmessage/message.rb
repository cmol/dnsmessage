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
      ptr = Pointer.new()
      parse_header(input)
      idx               = parse_questions(input, @qdcount, ptr)
      @answers, idx     = parse_records(input, @ancount, idx, ptr)
      @authority, idx   = parse_records(input, @nscount, idx, ptr)
      @additionals, idx = parse_records(input, @arcount, idx, ptr)
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

    def parse_questions(message, num_questions, ptr)
      idx = HEADER_SIZE # Header takes up the first 12 bytes
      @questions = (0...num_questions).map do
        Question.parse(message, ptr, idx).tap do | q |
          idx += q.size
        end
      end
      idx
    end

    def parse_records(message, num_records, idx, ptr)
      [num_records.times.map do
        ResourceRecord.parse(message[idx..-1],ptr).tap do | rr |
          ptr.add_arr(rr.add_to_hash,idx)
          idx += rr.size
        end
      end,
      idx]
    end

    def build
      ptr = Pointer.new()
      packet  = build_header
      packet << build_questions(ptr, packet.size)
      packet << build_answers(ptr, packet.size)
      packet << build_authority(ptr, packet.size)
      packet << build_additionals(ptr,packet.size)
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

    def build_questions(ptr, idx)
      @questions.map do | q |
        q.build(ptr,idx).tap do | bytes |
          idx += bytes.length
        end
      end.join("")
    end

    def build_answers(ptr, idx)
      build_record(ptr, idx, @answers)
    end

    def build_authority(ptr, idx)
      build_record(ptr, idx, @authority)
    end

    def build_additionals(ptr, idx)
      build_record(ptr, idx, @additionals)
    end

    def build_record(ptr, idx, records)
      records.map do | rr |
        rr.build(ptr,idx).tap do | r |
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
