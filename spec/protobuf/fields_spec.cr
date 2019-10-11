require "../spec_helper"

require "../fixtures/test.pb"

describe "Protobuf::Message::Fields" do
  it "reflects FIELDS" do
    Test::Fields["f1"]?.should be_a(Protobuf::Message::Field)

    f1 = Test::Fields["f1"]
    f1.name.should eq("f1")
    f1.type.should eq("String")
    f1.pb_type.should eq("string")
  end
end
