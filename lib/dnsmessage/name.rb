# frozen_string_literal: true

module DNSMessage
  # Parsing DNS names directly or using pointers
  module Name
    NAME_POINTER = 0xc0
    POINTER_MASK = 0x3fff

    def self.parse(record, ptr)
      # Read name loop
      idx = 0
      name = []
      loop do
        length = record[idx].unpack1("c")
        idx += 1
        break if length.zero?

        return parse_from_pointer(ptr, record, length, idx) \
          if length & NAME_POINTER == NAME_POINTER

        name << record[idx...idx + length]
        idx += length
      end
      [name.join("."), idx, true]
    end

    def self.build(name, ptr)
      if ptr.find(name)
        [[(ptr.find(name) | NAME_POINTER << 8)].pack("n"), false]
      else
        [name.split(".").map do |section|
          section.length.chr + section
        end.join("") << "\x0", # Terminate will nullptr
         true]
      end
    end

    def self.parse_from_pointer(ptr, record, length, idx)
      [ptr.find(((length << 8) | record[idx].unpack1("c")) & POINTER_MASK),
       idx + 1, false]
    end
  end
end
