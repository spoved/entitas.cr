require "../spec_helper"

def before
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

def before2
  contexts = Contexts.new
  sys = MultiReactiveSystemSpy.new(contexts)

  e1 = contexts.test.create_entity
  e1.add_name_age(name: "Max", age: 42)
  e1.del_name_age

  sys.execute

  {contexts, sys, e1}
end

describe Entitas::MultiReactiveSystem do
  describe "when triggered" do
    it "processes entities from different contexts" do
      _, sys, e1, e2 = before

      sys.entities.size.should eq 2
      sys.entities.includes?(e1).should be_true
      sys.entities.includes?(e2).should be_true

      e1.name_age.age.should eq 52
      e2.name_age.age.should eq 34
    end

    it "executes once" do
      _, sys, _ = before
      sys.did_execute.should eq 1
    end

    it "retains once even when multiple collectors contain entity" do
      _, sys = before
      sys.did_execute.should eq 1
    end

    it "can to_s" do
      _, sys, _ = before
      sys.to_s.should eq "MultiReactiveSystem(MultiReactiveSystemSpy)"
    end
  end

  describe "when multiple collectors are triggered with same entity" do
    it "executes once" do
      _, sys, _ = before2
      sys.did_execute.should eq 1
    end

    it "merges collected entities and removes duplicates" do
      _, sys, _ = before2
      sys.entities.size.should eq 1
    end

    it "clears merged collected entities" do
      _, sys, _ = before2
      sys.execute
      sys.did_execute.should eq 1
    end
  end
end
