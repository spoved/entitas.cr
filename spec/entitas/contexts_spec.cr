require "../spec_helper"

describe Contexts do
  it "should return the same shared instance" do
    ctxs = Contexts.shared_instance
    ctxs.shared_instance.should_not be_nil
    ctxs.should be Contexts.shared_instance
    Contexts.new.shared_instance.should be Contexts.shared_instance
  end

  it "should build entity indices" do
    ctxs = Contexts.shared_instance
    index = ctxs.test.get_entity_index(Contexts::NAME_AGE_ENTITY_INDICES_NAME)
    index.should be_a(Entitas::EntityIndex(TestEntity, String))
    index = index.as(Entitas::EntityIndex(TestEntity, String))
    index.get_entities("Monty").size.should eq 0
    ctxs.test.create_entity.add_name_age(name: "Monty")
    index.get_entities("Monty").size.should eq 1
  end
end
