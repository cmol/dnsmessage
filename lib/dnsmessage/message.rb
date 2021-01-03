module DNSMessage
  class Message

    NAME_POINTER = 0xc0
    POINTER_MASK = 0x3fff

    attr_accessor :domain_name, :query_type, :questions,
      :answers, :authority, :additionals
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
      idx = parse_records(input, @ancount, idx)
      idx = parse_records(input, @nscount, idx)
      idx = parse_records(input, @arcount, idx)
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
          return parse_name(message, ptr)
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
      idx = 12 # Header takes up the first 12 bytes
      @questions = (0...num_questions).map do
        name, idx = parse_name(message, idx)

        # take last four bytes
        type, klass = message[idx..-1].unpack("n2")
        [name, type, klass]
      end

      @domain_name = @questions.first[0]
      @query_type  = @questions.first[1]

      idx
    end

    def parse_records(message, num_records, idx)

    end

    def check_validity
      raise(StandardError, "Bad qr type") if @qr != 0
      raise(StandardError, "No questions in query") if @qdcount < 1
      raise(StandardError, "Empty domain")  if @domain_name.empty?
    end

  end
end
