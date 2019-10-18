# ```proto
# message Account {
#   optional string id                 = 1 ; // "18ce544yq30"
#   optional string timezone_switch_at = 7 ; // "2016-07-21T07:00:00Z"
#   optional string name               = 2 ; // "API McTestface"
# ```
#
# ```crystal
# schema = ProtobufSchema.parse(buf)
# schema.fields.map(&.name) # => ["id", "timezone_switch_at"], "name"]
# ```

class Protobuf::Schema
  alias Types = Int32 | Int64 | UInt32 | UInt64 | Int32 | Int64 | Bool | UInt64 | Int64 | Float64 | String | Slice(UInt8) | UInt32 | Int32 | Float32 | Nil | Array(Int32 | Int64 | UInt32 | UInt64 | Int32 | Int64 | Bool | UInt64 | Int64 | Float64 | String | Slice(UInt8) | UInt32 | Int32 | Float32 | Nil)

  PB_TYPE_MAP = {
    # wire type 0
    "int32"  => Int32,
    "int64"  => Int64,
    "uint32" => UInt32,
    "uint64" => UInt64,
    "sint32" => Int32,
    "sint64" => Int64,
    "bool"   => Bool,

    # wire type 1
    "fixed64"  => UInt64,
    "sfixed64" => Int64,
    "double"   => Float64,

    # wire type 2
    "string" => String,
    "bytes"  => Slice(UInt8),

    # wire type 5
    "fixed32"  => UInt32,
    "sfixed32" => Int32,
    "float"    => Float32,
  }

  WIRE_TYPES = {
    "int32"  => 0,
    "int64"  => 0,
    "uint32" => 0,
    "uint64" => 0,
    "sint32" => 0,
    "sint64" => 0,
    "bool"   => 0,

    "fixed64"  => 1,
    "sfixed64" => 1,
    "double"   => 1,

    "string" => 2,
    "bytes"  => 2,

    "fixed32"  => 5,
    "sfixed32" => 5,
    "float"    => 5,
  }
end

require "./schema/*"

class Protobuf::Schema
  getter version : Int32
  getter lines   : Array(Field | Text)
  getter fields  : Array(Field)
  getter texts   : Array(Text)
  getter by_id   : Hash(Int32, Field)
  getter by_name : Hash(String, Field)

  def initialize(@version, @klass_name : String, @lines : Array(Field | Text))
    @fields  = Array(Field).new
    @texts   = Array(Text).new
    @by_id   = Hash(Int32, Field).new
    @by_name = Hash(String, Field).new

    @lines.each do |field|
      case field
      when Field
        @fields << field
        @by_id[field.tag]    = field
        @by_name[field.name] = field
      when Text
        @texts << field
      end
    end
  end

  def []?(id : Int) : Field?
    by_id[id.to_i32]?
  end

  def []?(name : String) : Field?
    by_name[name]?
  end

  def to_s(io : IO)
    lines.each_with_index do |line, i|
      case line
      when Field
        io << "  "
      end
      io << line.to_s
      io << "\n" if !(i + 1 == lines.size)
    end
  end

  def from_protobuf(io)
    Message.new(self, Protobuf::Buffer.new(io))
  end

  def self.parse(buf : String) : Schema
    Parser.new(buf).parse
  end
end
