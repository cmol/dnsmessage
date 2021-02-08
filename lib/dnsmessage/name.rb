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
          return [name_pointers[ptr],idx+1,nil]
        elsif length == 0
          break
        else
          name << record[idx...idx+length]
          idx += length
        end
      end
      [name.join("."), idx, true]
    end

  end
end
