class Protobuf::Schema
  record Text,
    text : String do

    def to_s(io : IO)
      io << text
    end
  end
end
