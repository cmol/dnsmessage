# frozen_string_literal: true

module DNSMessage
  # Handle DNS pointers
  class Pointer
    def initialize(hash = {})
      @hash = hash
    end

    def add_arr(arr, offset)
      return unless arr

      arr.each do |k, v|
        k += offset if k.instance_of?(Integer)
        v += offset if v.instance_of?(Integer)
        add(k, v)
      end
    end

    def add(key, value)
      if key.instance_of?(Integer)
        add_name(key, value)
      else
        add_ptr(key, value)
      end
    end

    def to_h
      @hash
    end

    def find(key)
      @hash[key]
    end

    private

    def add_name(key, value)
      value = value.split(".")
      loop do
        return unless value.length > 1

        @hash[key] = value.join(".")
        key += value.shift.length + 1
      end
    end

    def add_ptr(key, value)
      key = key.split(".")
      loop do
        return unless key.length > 1

        @hash[key.join(".")] = value
        value += key.shift.length + 1
      end
    end
  end
end
