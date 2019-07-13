require "../spec_helper"

describe Entitas::Component do
  it "should add methods" do
    entity = Entitas::Entity.new
    entity.add_a
    entity.a.should be_a A
    entity.del_a
    entity.a.should be_nil
  end

  it "should be able to be initalized with vars" do
    comp = UniqueComp.new(size: 5)
    comp.size.should eq 5
    comp.default.should eq "foo"
    comp = UniqueComp.new(size: 4, default: "bar")
    comp.size.should eq 4
    comp.default.should eq "bar"
  end
end
