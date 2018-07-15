require "../spec_helper"

describe Entitas::Component do
  describe "#prop" do
    it "can define a property" do
      comp = TestComponent.new
      comp.set_size(1)
      comp.get_size.should eq 1
    end

    it "can define default value" do
      comp = TestComponent.new
      comp.get_default.should eq "hello"
    end

    it "can change the property value" do
      comp = TestComponent.new
      comp.get_default.should eq "hello"
      comp.set_default("world")
      comp.get_default.should eq "world"
    end
  end

  describe "#is_unique?" do
    it "can be defined as unique" do
      Entitas::Component.is_unique?.should be_false
      TestComponent.is_unique?.should be_true
    end
  end

  describe "#component_is_unique?" do
    it "can be defined as unique" do
      Entitas::Component.is_unique?.should be_false
      TestComponent.is_unique?.should be_true
      TestComponent.new.component_is_unique?.should be_true
    end
  end
end
