require "../spec_helper"

require "../fixtures/test.pb"

private def schema_v2 : String
  <<-EOF
    syntax = "proto2";

    message Test {
      required string f1 = 1;
      repeated uint64 fa = 3;
      optional bytes bbbb = 7;
    }
    EOF
end

private def schema_v3 : String
  <<-EOF
    syntax = "proto3";

    message Test {
      string f1 = 1;
      repeated uint64 fa = 3;
      bytes bbbb = 7;
    }
    EOF
end

private def versioned_schemas
  {
    2 => schema_v2,
    3 => schema_v3,
  }
end

describe Protobuf::Schema do
  describe ".parse(buf)" do
    it "returns Protobuf::Schema (v2)" do
      schema = Protobuf::Schema.parse(schema_v2)
      schema[1]?.to_s.should eq("required string f1 = 1;")
      schema[2]?.to_s.should eq("")
      schema[3]?.to_s.should eq("repeated uint64 fa = 3;")
      schema[7]?.to_s.should eq("optional bytes bbbb = 7;")

      schema["f1"]?.to_s.should eq("required string f1 = 1;")
      schema["xx"]?.to_s.should eq("")
      schema["fa"]?.to_s.should eq("repeated uint64 fa = 3;")
      schema["bbbb"]?.to_s.should eq("optional bytes bbbb = 7;")
    end

    it "returns Protobuf::Schema (v3)" do
      schema = Protobuf::Schema.parse(schema_v3)
      schema[1]?.to_s.should eq("string f1 = 1;")
      schema[2]?.to_s.should eq("")
      schema[3]?.to_s.should eq("repeated uint64 fa = 3;")
      schema[7]?.to_s.should eq("bytes bbbb = 7;")

      schema["f1"]?.to_s.should eq("string f1 = 1;")
      schema["xx"]?.to_s.should eq("")
      schema["fa"]?.to_s.should eq("repeated uint64 fa = 3;")
      schema["bbbb"]?.to_s.should eq("bytes bbbb = 7;")
    end
  end

  describe "#from_protobuf(io)" do
    versioned_schemas.each do |version, schema_v|
      it "decodes (v#{version})" do
        schema = Protobuf::Schema.parse(schema_v)
        File.open("#{__DIR__}/../fixtures/test.data.encoded") do |io|
          test = schema.from_protobuf(io)
          test["f1"].should eq("dsfadsafsaf")
          test["f1"]?.should eq("dsfadsafsaf")
          test["fa"]?.should eq([2342134, 2342135, 2342136])
          test["bbbb"]?.should eq(Bytes[0, 1, 2, 255, 254, 253])

          expect_raises(Protobuf::Error, /Field not found/) do
            test["XX"]
          end
          test["XX"]?.should eq(nil)
        end
      end
    end
  end

  describe "#to_s" do
    versioned_schemas.each do |version, schema_v|
      it "builds schema string itself (v#{version})" do
        schema = Protobuf::Schema.parse(schema_v)
        schema.to_s.should eq(schema_v)
      end
    end
  end
end

describe Protobuf::Schema::Message do
  describe "#to_protobuf" do
    versioned_schemas.each do |version, schema_v|
      if version == 3
        pending "encodes (v#{version}) # proto3 is buggy https://github.com/jeromegn/protobuf.cr/issues/23" do
        end
        next
      end

      it "encodes (v#{version})" do
        File.open("#{__DIR__}/../fixtures/test.data.encoded") do |io|
          test1 = Protobuf::Schema.parse(schema_v).from_protobuf(io)
          test2 = Protobuf::Schema.parse(schema_v).from_protobuf(test1.to_protobuf.tap(&.rewind))
          test2["f1"].should eq("dsfadsafsaf")
          test2["f1"]?.should eq("dsfadsafsaf")
          test2["fa"]?.should eq([2342134, 2342135, 2342136])
          test2["bbbb"]?.should eq(Bytes[0, 1, 2, 255, 254, 253])
        end
      end
    end
  end
end
