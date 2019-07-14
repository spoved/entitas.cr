require "../spec_helper"

describe Entitas::Entity do
  it "has no components by defualt" do
    entity = Entitas::Entity.new(1)
    entity.a.should be_nil
    entity.get_components.size.should eq 0
  end

  it "can add flag components" do
    entity = Entitas::Entity.new(1)

    entity.add_a
    entity.a.should be_a A
    entity.get_components.size.should eq 1
  end
end
