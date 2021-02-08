module DNSMessage
  module Name

  NAME_POINTER = 0xc0
  POINTER_MASK = 0x3fff

    def self.parse(record, name_pointers)
      # Read name loop
      idx = 0
      name = []
      loop do
        length = record[idx].unpack("c").first
        idx += 1
        if length & NAME_POINTER == NAME_POINTER
          ptr = ((length << 8) | record[idx].unpack("c").first) & POINTER_MASK
          return [name_pointers[ptr],idx+1,false]
        elsif length == 0
          break
        else
          name << record[idx...idx+length]
          idx += length
        end
      end
      [name.join("."), idx, true]
    end

    def self.build(name,name_pointers)
      if name_pointers[name]
        [[(name_pointers[name] | NAME_POINTER << 8)].pack("n"),false]
      else
        [name_bytes = name.split(".").map do | section |
          section.length.chr + section
        end.join("") + "\x0", # Terminate will nullptr
        true]
      end
    end

  end
end
