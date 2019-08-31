require "../spec_helper"

MATCHER_AB = Entitas::Matcher.all_of A, B

private def assert_entities(sys : ReactiveSystemSpy, entity, did_execute = 1)
  if entity.nil?
    sys.did_execute.should eq 0
    sys.entities.should be_empty
  else
    sys.did_execute.should eq did_execute
    sys.entities.size.should eq 1
    sys.entities.includes?(entity).should be_true
  end
end

private def create_entity_ab(ctx)
  ctx.create_entity.add_a.add_b
end

private def create_entity_ac(ctx)
  ctx.create_entity.add_a.add_c
end

private def create_entity_abc(ctx)
  ctx.create_entity.add_a.add_b.add_c
end

private def multi_contexts
  ctx1 = MyTestContext.new
  ctx2 = MyTestContext.new

  group_a = ctx1.get_group(MyTestMatcher.all_of(A))
  group_b = ctx2.get_group(MyTestMatcher.all_of(B))
  groups = [group_a, group_b]
  group_events = [
    Entitas::Events::GroupEvent::Added,
    Entitas::Events::GroupEvent::Removed,
  ]

  collector = Entitas::Collector.new(groups, group_events)
  sys = ReactiveSystemSpy.new collector

  {sys, ctx1, ctx2, group_a, group_b}
end

private def new_system
  ctx = new_context
  sys = ReactiveSystemSpy.new(ctx.create_collector(MATCHER_AB))
  {ctx, sys}
end

private def new_system_removed
  ctx = new_context
  sys = ReactiveSystemSpy.new(ctx.create_collector(MATCHER_AB.removed))
  {ctx, sys}
end

private def new_system_added_or_removed
  ctx = new_context
  sys = ReactiveSystemSpy.new(ctx.create_collector(MATCHER_AB.added_or_removed))
  {ctx, sys}
end

describe Entitas::ReactiveSystem do
  describe "OnEntityAdded" do
    it "does not execute when no entities were collected" do
      _, sys = new_system
      sys.execute
      assert_entities(sys, nil)
    end

    it "executes when triggered" do
      ctx, sys = new_system
      e = create_entity_ab(ctx)
      sys.execute
      assert_entities(sys, e)
    end

    it "executes only once when triggered" do
      ctx, sys = new_system
      e = create_entity_ab(ctx)
      sys.execute
      sys.execute
      assert_entities(sys, e)
    end

    it "retains and releases collected entities" do
      ctx, sys = new_system
      e = create_entity_ab(ctx)
      r_count = e.retain_count
      sys.execute

      r_count.should eq 3        # retained by context, group and collector
      e.retain_count.should eq 2 # retained by context and group

    end

    it "collects changed entities in execute" do
      ctx, sys = new_system
      e = create_entity_ab(ctx)
      sys.execute_action = ->(entities : Array(Entitas::IEntity)) { entities.first.as(TestEntity).replace_a(A.new); nil }
      sys.execute
      sys.execute
      assert_entities(sys, e, 2)
    end

    it "collects created entities in execute" do
      ctx, sys = new_system
      e1 = create_entity_ab(ctx)
      e2 : Entitas::IEntity? = nil
      sys.execute_action = ->(entities : Array(Entitas::IEntity)) do
        e2 = create_entity_ab(ctx) if e2.nil?
        nil
      end

      sys.execute
      assert_entities(sys, e1)

      sys.execute
      assert_entities(sys, e2, 2)
    end

    it "doesn't execute when not triggered" do
      ctx, sys = new_system
      ctx.create_entity.add_a
      sys.execute
      assert_entities(sys, nil)
    end

    it "deactivates and will not trigger" do
      ctx, sys = new_system
      sys.deactivate
      create_entity_ab(ctx)
      sys.execute
      assert_entities(sys, nil)
    end

    it "activates and will trigger again" do
      ctx, sys = new_system
      sys.deactivate
      sys.activate

      e = create_entity_ab(ctx)
      sys.execute
      assert_entities(sys, e)
    end

    it "clears" do
      ctx, sys = new_system
      create_entity_ab(ctx)
      sys.clear
      sys.execute
      assert_entities(sys, nil)
    end

    it "can to_s" do
      _, sys = new_system
      sys.to_s.should eq "ReactiveSystem(ReactiveSystemSpy)"
    end
  end

  describe "OnEntityRemoved" do
    it "executes when triggered" do
      ctx, sys = new_system_removed
      e = create_entity_ab(ctx).remove_a
      sys.execute
      assert_entities(sys, e)
    end

    it "executes only once when triggered" do
      ctx, sys = new_system_removed
      e = create_entity_ab(ctx).remove_a
      sys.execute
      sys.execute
      assert_entities(sys, e)
    end

    it "doesn't execute when not triggered" do
      ctx, sys = new_system_removed
      create_entity_ab(ctx).add_c.remove_c
      sys.execute
      assert_entities(sys, nil)
    end

    it "retains entities until execute completed" do
      ctx, sys = new_system_removed
      e = create_entity_ab(ctx)
      did_execute = 0

      sys.execute_action = ->(entities : Array(Entitas::IEntity)) do
        did_execute += 1
        entities.first.retain_count.should eq 1
        nil
      end

      e.destroy
      sys.execute
      did_execute.should eq 1
      e.retain_count.should eq 0
    end
  end

  describe "OnEntityAddedOrRemoved" do
    it "executes when added" do
      ctx, sys = new_system_added_or_removed
      e = create_entity_ab(ctx)
      sys.execute
      assert_entities(sys, e)
    end

    it "executes when removed" do
      ctx, sys = new_system_added_or_removed
      e = create_entity_ab(ctx)
      sys.execute
      e.del_a
      sys.execute
      assert_entities(sys, e, 2)
    end
  end

  describe "multiple contexts" do
    it "executes when a triggered by collector" do
      sys, ctx1, ctx2 = multi_contexts

      ea1 = ctx1.create_entity.add_a
      ctx2.create_entity.add_a

      eb1 = ctx1.create_entity.add_b
      eb2 = ctx2.create_entity.add_b

      sys.execute
      assert_entities(sys, ea1)

      eb1.del_b
      eb2.del_b

      sys.execute
      assert_entities(sys, eb2, 2)
    end
  end

  it "filter entities" do
    ctx = new_context

    filter_proc = ->(entity : Entitas::IEntity) do
      entity = entity.as(TestEntity)
      comp = entity.get_component(Entitas::Component::Index::NameAge)
      if comp.nil?
        false
      else
        if comp.as(NameAge).age.nil?
          false
        else
          comp.as(NameAge).age.as(Int32) > 42
        end
      end
    end

    sys = ReactiveSystemSpy.new(ctx.create_collector(Entitas::Matcher.all_of(B, NameAge)), filter_proc)
    ctx.create_entity.add_a.add_c
    eab1 = ctx.create_entity
    eab1.add_b
    eab1.add_component(NameAge.new(age: 10))

    eab2 = ctx.create_entity
    eab2.add_b
    eab2.add_component(NameAge.new(age: 50))

    did_execute = 0
    sys.execute_action = ->(entities : Array(Entitas::IEntity)) do
      did_execute += 1
      eab2.retain_count.should eq 3
      nil
    end

    sys.execute
    did_execute.should eq 1

    sys.execute
    sys.entities.size.should eq 1
    sys.entities.first.should be eab2

    eab1.retain_count.should eq 2
    eab1.retain_count.should eq 2
  end

  describe "clear" do
    it "clears reactive system after execute" do
      ctx, sys = new_system
      sys.execute_action = ->(entities : Array(Entitas::IEntity)) do
        entities[0].as(TestEntity).replace_a(A.new)
        nil
      end

      e = create_entity_ab(ctx)
      sys.execute
      sys.clear
      sys.execute
      assert_entities(sys, e)
    end
  end
end
