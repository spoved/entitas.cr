require "../spec_helper"

describe Entitas::Entity do
  describe "#context" do
    it "created a Game context" do
      game = ::GameContext.new(1, 0, nil, nil)
      game.should be_a(::GameContext)
      game.should be_a(Entitas::Context)
    end
  end

  describe "#contexts" do
    it "created a Game and Input context" do
      game = ::GameContext.new(1, 0, nil, nil)
      game.should be_a(::GameContext)
      game.should be_a(Entitas::Context)
      input = ::InputContext.new(1, 0, nil, nil)
      input.should be_a(::InputContext)
      input.should be_a(Entitas::Context)
    end
  end

  describe "#component" do
    it "created component methods" do
      comp = TestComponent.new
      comp.set_size(1)
      entity = TestEntity.new
      entity.add_test(comp)
    end
  end
end
