require "../spec_helper"

def before
  # var contexts = new Contexts();
  # system = new MultiReactiveSystemSpy(contexts);
  # system.executeAction = entities => {
  #     foreach (var e in entities) {
  #         e.nameAge.age += 10;
  #     }
  # };
  #
  # e1 = contexts.test.CreateEntity();
  # e1.AddNameAge("Max", 42);
  #
  # e2 = contexts.test2.CreateEntity();
  # e2.AddNameAge("Jack", 24);
  #
  # system.Execute();

  contexts = Contexts.new
  sys = MultiReactiveSystemSpy.new(contexts)
  sys.execute_action = ->(entities : Array(Entitas::Entity)) do
    entities.each do |e|
      e.name_age.age += 10
    end
  end

  e1 = contexts.test.create_entity
  e1.add_name_age(name: "Max", age: 42)

  e2 = contexts.test.create_entity
  e2.add_name_age(name: "Jack", age: 24)
  sys.execute

  {contexts, sys, e1, e2}
end

describe Entitas::MultiReactiveSystem do
  describe "when triggered" do
    it "processes entities from different contexts" do
      ctxs, sys, e1, e2 = before
    end
  end
end
