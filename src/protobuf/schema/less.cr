class Protobuf::Schema
  class Less
    alias Reader = Proc(Buffer, Types)

    DEFAULT_READERS = {
      0 => "uint64", # [varint] int32, int64, uint32, uint64, sint32, sing64, bool, enum
      1 => "double", # [64-bit] fixed64, sfixed64, double
      2 => "string", # [Length-delimited] string, bytes, embedded messages, packed repeated fields
      5 => "float" , # [32-bit] fixed32, sfix3d32, float
    }

    TYPED_READERS = {
      "int32"    => ->(buf : Buffer) { buf.read_int32 },
      "int64"    => ->(buf : Buffer) { buf.read_int64 },
      "uint32"   => ->(buf : Buffer) { buf.read_uint32 },
      "uint64"   => ->(buf : Buffer) { buf.read_uint64 },
      "sint32"   => ->(buf : Buffer) { buf.read_sint32 },
      "sint64"   => ->(buf : Buffer) { buf.read_sint64 },
      "bool"     => ->(buf : Buffer) { buf.read_bool },

      "fixed64"  => ->(buf : Buffer) { buf.read_fixed64 },
      "sfixed64" => ->(buf : Buffer) { buf.read_sfixed64 },
      "double"   => ->(buf : Buffer) { buf.read_double },

      "string"   => ->(buf : Buffer) { buf.read_string },
      "bytes"    => ->(buf : Buffer) { buf.read_bytes },

      "fixed32"  => ->(buf : Buffer) { buf.read_fixed32 },
      "sfixed32" => ->(buf : Buffer) { buf.read_sfixed32 },
      "float"    => ->(buf : Buffer) { buf.read_float },
    }
    
    def initialize(buf : Buffer, option = nil)
      wired_readers = option || DEFAULT_READERS
      @attrs = Hash(UInt64, Types).new

      loop do
        tag_id, wire = buf.read_info
        tag_id || break

        reader = wired_readers[wire]?
        reader = underlying_reader!(reader)
        v = reader.try(&.call(buf))

        if @attrs.has_key?(tag_id)
          existing = @attrs[tag_id]
          case existing
          when Array
            v = [v] if !v.is_a?(Array)
            v = (existing + v).as(Types)
            @attrs[tag_id] = v
          else
            @attrs[tag_id] = [existing, v].as(Types)
          end
        else
          @attrs[tag_id] = v
        end
      end
    end

    def [](key : Int)
      key = key.to_u64
      if @attrs.has_key?(key)
        @attrs[key]
      else
        raise Protobuf::Error.new("Field not found: `#{key}`")
      end
    end

    def []?(key : Int)
      @attrs[key.to_u64]?
    end

    def to_hash
      @attrs
    end
    
    def to_s(io : IO)
      io << @attrs.inspect
    end

    def inspect(io : IO)
      if @attrs.size <= 1
        io << '{'
        @attrs.each do |tag, v|
          io << "#{tag}: #{v.inspect}"
          break
        end
        io << '}'
      else
        tag_max_size = @attrs.keys.max.to_s.size
        io << "{\n"
        @attrs.each_with_index do |(tag, v), i|
          io << "  %#{tag_max_size}s: %s,\n" % [tag, v.inspect]
        end
        io << "}"
      end
    end
    
    private def underlying_reader!(reader)
      case reader
      when Nil
        return nil
      when Reader
        return reader
      when String
        return TYPED_READERS[reader]? || raise ArgumentError.new("unknown pb_type: #{reader.inspect}")
      else
        raise "unknown reader: #{reader.inspect}"
      end
    end
  end
end

class Protobuf::Schema::Less
  def self.from_protobuf(io : IO | Bytes, option = nil)
    io = IO::Memory.new(io) if io.is_a?(Bytes)
    Less.new(Buffer.new(io), option)
  end

  def self.from_protobuf(bytes : String, option = nil)
    case bytes
    when /\A[a-f0-9\s]+\Z/i
      from_protobuf(bytes.gsub(/\s+/, "").hexbytes, option)
    else
      raise ArgumentError.new("unsupported bytes: #{bytes.inspect}")
    end
  end
end

def Protobuf.decode(v, option = nil)
  Protobuf::Schema::Less.from_protobuf(v, option).to_hash
end
