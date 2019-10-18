require "../spec_helper"

describe Protobuf do
  describe ".decode" do
    it "returns decoded data as Hash" do
      Protobuf.decode("08 01")                .should eq({1 => 1})
      Protobuf.decode("08 01 08 02")          .should eq({1 => [1,2]})
      Protobuf.decode("0a 03 66 6f 6f 10 14") .should eq({1 => "foo", 2 => 20})
    end

    it "can control the reading strategy for each wire" do
      Protobuf.decode("08 01", {0 => "int32"}) .should eq({1 => 1})
      Protobuf.decode("08 01", {0 => "bool" }) .should eq({1 => true})

      expect_raises(ArgumentError, /unknown.*xxx/) do
        Protobuf.decode("08 01", {0 => "xxx"})
      end
    end
  end
end

describe Protobuf::Schema::Less do
  describe ".from_protobuf(io)" do
    it "returns a Protobuf::Schema::Less" do
      msg = Protobuf::Schema::Less.from_protobuf(Bytes[0x08,0x01,0x10,0x01,0x10,0x02])
      msg[1]?.should eq(1)
      msg[2]?.should eq([1,2])
      msg[3]?.should eq(nil)
      msg.to_hash.should eq({1 => 1, 2 => [1,2]})
      msg.inspect.should eq <<-EOF
        {
          1: 1,
          2: [1, 2],
        }
        EOF
    end
  end
end
