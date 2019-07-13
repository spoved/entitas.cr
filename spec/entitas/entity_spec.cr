require "../spec_helper"

describe Entitas::Entity do
  it "can add flag components" do
    entity = Entitas::Entity.new
    entity.add_a
    entity.a.should be_a A
  end
end
