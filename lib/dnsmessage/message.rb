# frozen_string_literal: true

module DNSMessage
  # Message is the central class that most users of the API will use
  class Message
    NAME_POINTER = 0xc0
    POINTER_MASK = 0x3fff
    QUERY        = 0
    REPLY        = 1
    HEADER_SIZE  = 12

    attr_accessor :questions, :answers, :authority, :additionals,
                  :id, :qr, :opcode, :aa, :tc, :rd, :ra, :z, :rcode
    attr_reader :qdcount, :ancount, :nscount, :arcount

    def initialize
      @questions   = []
      @answers     = []
      @additionals = []
      @authority   = []
      @qdcount     = 0
      @ancount     = 0
      @nscount     = 0
      @arcount     = 0
      @id = @qr = @opcode = @aa = @tc = @rd = @ra = @z = @rcode = 0
    end

    def parse(input)
      ptr = Pointer.new
      parse_header(input)
      idx = parse_questions(input, @qdcount, ptr)
      @answers, idx = parse_records(input, @ancount, idx, ptr)
      @authority, idx = parse_records(input, @nscount, idx, ptr)
      @additionals, = parse_records(input, @arcount, idx, ptr)
    end

    def self.parse(input)
      new.tap do |m|
        m.parse(input)
      end
    end

    def self.reply_to(query)
      new.tap do |r|
        r.id = query.id
        r.qr = REPLY
        r.questions = query.questions
      end
    end

    def parse_header(message)
      return nil if message.nil? || message.empty?

      @id, opts, @qdcount, @ancount, @nscount, @arcount =
        message[0...12].unpack("n6")

      parse_opts(opts)
    end

    def parse_opts(opts)
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
        Question.parse(message, ptr, idx).tap do |q|
          idx += q.size
        end
      end
      idx
    end

    def parse_records(message, num_records, idx, ptr)
      [num_records.times.map do
        ResourceRecord.parse(message[idx..], ptr).tap do |rr|
          ptr.add_arr(rr.add_to_hash, idx)
          idx += rr.size
        end
      end,
       idx]
    end

    def build
      ptr = Pointer.new
      packet = build_header
      packet << build_questions(ptr, packet.size)
      packet << build_answers(ptr, packet.size)
      packet << build_authority(ptr, packet.size)
      packet << build_additionals(ptr, packet.size)
    end

    def build_header
      [@id, build_opts,
       @questions.length,
       @answers.length,
       @authority.length,
       @additionals.length].pack("n6")
    end

    def build_opts
      build_qr | build_opcode | build_aa | build_tc | build_rd | build_ra |
        build_z | build_rcode
    end

    def build_qr
      (@qr & 0x1) << 15
    end

    def build_opcode
      (@opcode & 0xf) << 11
    end

    def build_aa
      (@aa & 0x1) << 10
    end

    def build_tc
      (@tc & 0x1) << 9
    end

    def build_rd
      (@rd & 0x1) << 8
    end

    def build_ra
      (@ra & 0x1) << 7
    end

    def build_z
      (@z & 0x1) << 7
    end

    def build_rcode
      (@rcode & 0xf)
    end

    def build_questions(ptr, idx)
      @questions.map do |q|
        q.build(ptr, idx).tap do |bytes|
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
      records.map do |rr|
        rr.build(ptr, idx).tap do |r|
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
