class Protobuf::Schema
  class Message
    getter schema : Schema
    getter attrs  : Hash(String, Types)
    
    def initialize(@schema, buf : Protobuf::Buffer)
      @attrs = Hash(String, Types).new

      loop do
        tag_id, wire = buf.read_info

        case tag_id
        when UInt64
          if field = schema[tag_id]?
            v = field.from_protobuf(buf)
            if field.repeated?
              v = [v]
              a = @attrs[field.name]?
              case a
              when Array
                v = a + v
              when Nil
              else
                raise "[BUG] #{field.name} is repeated, but already set #{a.class}"
              end
            end
            @attrs[field.name] = v
          else
            buf.skip(wire)
            next
          end
        when Nil
          break
        end
      end
    end

    def [](key : String)
      if schema[key]?
        @attrs[key]
      else
        raise Protobuf::Error.new("Field not found: `#{key}`")
      end
    end

    def []?(key : String)
      self[key]
    rescue Protobuf::Error
      nil
    end

    def to_protobuf
      io = IO::Memory.new
      to_protobuf(io)
      io
    end

    def to_protobuf(io : IO, embedded = false)
      buf = Protobuf::Buffer.new(io)
      schema.fields.each do |field|
        if value = self[field.name]?
          field.to_protobuf(buf, value)
        end
      end
    end
  end
end
