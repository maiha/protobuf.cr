class Protobuf::Schema
  class Field
    property version : Int32
    property rule    : String?
    property type    : String
    property name    : String
    property tag     : Int32
    property memo    : String
    property packed  : Bool

    def initialize(@version, @rule, @type, @name, @tag, @packed = false, memo : String? = nil)
      @memo = memo || ""
    end

    def enum?
      # TODO
      false
    end
    
    def wire
      Protobuf::Schema::WIRE_TYPES[type]? || (enum? ? 0 : 2)
    end
    
    def optional?
      rule == "optional"
    end
    
    def required?
      rule == "required"
    end
    
    def repeated?
      rule == "repeated"
    end
    
    def crystal_type?
      PB_TYPE_MAP[type]?
    end
    
    def native?
      !! crystal_type?
    end

    {% begin %}
    def from_protobuf(buf)
      case type
      {% for type, klass in Protobuf::Schema::PB_TYPE_MAP %}
        when {{type}}
          buf.read_{{ type.id }}
      {% end %}
      else
        # TODO: raise?
        nil
      end
    end
    {% end %}

    def to_protobuf(buf : Protobuf::Buffer, value)
      value || return
      # TODO: enum
      if repeated?
        if should_pack?
          if value.is_a?(Array)
            buf.write_info(tag, 2)
            buf.write_packed(value, type)
          end
        else
          if value.is_a?(Array)
            value.each do |v|
              to_protobuf(buf, tag, wire, v)
            end
          else
            # TODO: raise?
          end
        end
      else
        to_protobuf(buf, tag, wire, value)
      end
    end

    {% begin %}
    def to_protobuf(buf : Protobuf::Buffer, tag, wire, value)
      case type
      {% for type, klass in Protobuf::Schema::PB_TYPE_MAP %}
        when {{type}}
          buf.write_info(tag, wire)
          buf.write_{{type.id}}(value.as({{klass}}))
      {% end %}
      else
        raise NotImplementedError.new("#{self.class}#to_protobuf supports only native types")
      end
    end
    {% end %}

    def to_s(io : IO)
      io << "#{rule} " if rule
      io << "#{type} #{name} = #{tag};"
      io << " // #{memo}" if !memo.empty?
    end

    private def should_pack?
      (version != 2 && native?) || packed
    end
  end
end
