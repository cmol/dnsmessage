# frozen_string_literal: true

module DNSMessage
  class Question

    attr_accessor :name, :type, :klass
    attr_reader :size, :add_to_hash

    def initialize(name: nil, type: nil, klass: Class::IN)
      @name  = name
      @type  = type
      @klass = klass
    end

    def self.parse(question, ptr, idx)
      self.new().tap do | q |
        q.parse(question, ptr, idx)
      end
    end

    def parse(question, ptr, idx)
        @name, @size, add = Name.parse(question[idx..-1], ptr)
        ptr.add(idx, @name) if add

        # take last four bytes
        @type, @klass = question[(idx+@size)..-1].unpack("n2")
        @size += 4
    end

    def build(ptr,idx)
        name_bytes, add = Name.build(@name,ptr)
        ptr.add(@name, idx) if add
        name_bytes + [type,klass].pack("n2")
    end

  end
end
