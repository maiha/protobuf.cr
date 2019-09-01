require "../spec_helper"

private struct Test2
  include Protobuf::Message

  contract do
    required :a, :String, 1
    optional :b, :int32 , 2
    repeated :c, :int32 , 3
  end
end

describe Protobuf::Message do
  describe ".from_json" do
    it "works" do
      pb = Test2.from_json <<-EOF
        {
          "a": "foo",
          "b": 1,
          "c": [2,3]
        }
        EOF
      pb.a.should eq "foo"
      pb.b.should eq 1
      pb.c.should eq [2,3]
    end

    it "works with optional" do
      pb = Test2.from_json <<-EOF
        {
          "a": "foo"
        }
        EOF
      pb.a.should eq "foo"
      pb.b.should eq nil
      pb.c.should eq nil
    end
  end
end
