require "../spec_helper"

TOTAL_COMPONENTS = 27

describe Entitas::Component do
  it "should have #{TOTAL_COMPONENTS} total components" do
    Entitas::Component::TOTAL_COMPONENTS.should eq TOTAL_COMPONENTS
  end

  it "should add methods" do
    entity = new_entity
    entity.add_a
    entity.has_a?.should be_truthy
    entity.a.should be_a A
    entity.del_a
    entity.has_a?.should be_falsey
    expect_raises Entitas::Entity::Error::DoesNotHaveComponent do
      entity.a
    end
  end

  it "should be able to be initalized with vars" do
    comp = UniqueComp.new(size: 5)
    comp.size.should eq 5
    comp.default.should eq "foo"
    comp = UniqueComp.new(size: 4, default: "bar")
    comp.size.should eq 4
    comp.default.should eq "bar"
  end

  it "should initialize with custom constructor" do
    comp = Vector3.new
    comp.custom.should eq "Hello im a constructor"
  end
end
