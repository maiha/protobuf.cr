require "../spec_helper"

require "../fixtures/test.pb"

describe Protobuf::Message do
  describe "#[key]" do
    context "when the key is a member" do
      it "acts as #key" do
        File.open("#{__DIR__}/../fixtures/test.data.encoded") do |io|
          test = Test.from_protobuf(io)
          test["f1"].should eq("dsfadsafsaf")
        end
      end
    end

    context "when the key is not a member" do
      it "raises a runtime error" do
        File.open("#{__DIR__}/../fixtures/test.data.encoded") do |io|
          test = Test.from_protobuf(io)
          expect_raises(Protobuf::Error, /Field not found/) do
            test["XX"]
          end
        end
      end
    end
  end

  describe "#[key]=(val)" do
    context "when the key is a member and val is valid type" do
      it "acts as #key=" do
        File.open("#{__DIR__}/../fixtures/test.data.encoded") do |io|
          test = Test.from_protobuf(io)
          test["f1"] = "foo"
          test["f1"].should eq("foo")
          test.f1.should eq("foo")

          test["f2"] = -1_i64
          test["f2"].should eq(-1_i64)
          test.f2.should eq(-1_i64)
        end
      end
    end

    context "when the key is a member and val type is mismatch" do
      it "raises ArgumentError" do
        File.open("#{__DIR__}/../fixtures/test.data.encoded") do |io|
          test = Test.from_protobuf(io)
          expect_raises(ArgumentError, "f1 expected `String`, but got `Int32`") do
            test["f1"] = 2
          end

          expect_raises(ArgumentError, "f2 expected `Int64`, but got `String`") do
            test["f2"] = "foo"
          end
        end
      end
    end

    context "when the key is not a member" do
      it "raises a runtime error" do
        File.open("#{__DIR__}/../fixtures/test.data.encoded") do |io|
          test = Test.from_protobuf(io)
          expect_raises(Protobuf::Error, /Field not found/) do
            test["XX"] = nil
          end
        end
      end
    end
  end
end
