require "../spec_helper"

private def new_group_a
  Entitas::Group.new(Entitas::Matcher.all_of(A))
end

private def new_group_a_w_e
  matcher = Entitas::Matcher.all_of(A)
  matcher.component_names = ["A"]

  group = Entitas::Group.new(matcher)

  entity = new_entity_with_a
  group.handle_add_ea(entity)
  {group, entity}
end

private def new_group_with_cache
  group, entity = new_group_a_w_e
  cache = group.get_entities
  {group, entity, cache}
end

private def new_group_with_single_cache
  group, entity = new_group_a_w_e
  cache = group.get_single_entity
  {group, entity, cache}
end

private def assert_contains(group, expected_entites)
  group.size.should eq expected_entites.size
  entities = group.get_entities
  entities.size.should eq expected_entites.size

  expected_entites.each do |e|
    entities.includes?(e).should be_true
    group.includes?(e).should be_true
  end
end

private def assert_not_contains(group, entity)
  group.size.should eq 0
  group.get_entities.should be_empty
  group.has_entity?(entity).should be_false
end

module Entitas
  class Group
    def handle_silently(entity)
      handle_entity_silently(entity)
    end

    def handle(entity : Entitas::Entity, index, component)
      handle_entity(entity, index, component)
    end

    def handle_add_ea(entity : Entitas::Entity)
      handle(entity, Entitas::Component::Index::A.value, entity.a)
    end

    def handle_add_eb(entity : Entitas::Entity)
      handle(entity, Entitas::Component::Index::B.value, entity.b)
    end

    def handle_remove_ea(entity : Entitas::Entity, component)
      handle(entity, Entitas::Component::Index::A.value, component)
    end

    def update_ea(entity : Entitas::Entity, prev_component, new_component)
      update_entity(entity, Entitas::Component::Index::A.value, prev_component, new_component)
    end
  end
end

describe Entitas::Group do
  describe "initial state" do
    it "doesn't have entities which haven't been added" do
      group_a = new_group_a
      new_entity
      new_entity
      group_a.get_entities.should be_empty
    end

    it "doesn't add entities to buffer" do
      group_a = new_group_a
      buff = Array(Entitas::Entity).new
      buff << new_entity_with_a
      ret_buff = group_a.get_entities(buff)
      ret_buff.should be_empty
      ret_buff.should be buff
    end

    it "is empty" do
      new_group_a.size.should eq 0
    end

    it "doesn't contain entity" do
      e_a1 = new_entity
      new_group_a.has_entity?(e_a1).should be_false
    end
  end

  describe "when entity is matching" do
    it "adds matching entity" do
      group_a, e_a1 = new_group_a_w_e
      assert_contains(group_a, [e_a1])
    end

    it "fills buffer with entities" do
      group_a, e_a1 = new_group_a_w_e
      buff = Array(Entitas::Entity).new
      group_a.get_entities(buff)
      buff.size.should eq 1
      buff.first.should eq e_a1
    end

    it "clears buffer before filling" do
      buff = Array(Entitas::Entity).new
      group_a, e_a1 = new_group_a_w_e

      buff << new_entity
      buff << new_entity_with_a

      group_a.get_entities(buff)

      buff.size.should eq 1
      buff.first.should be e_a1
    end

    it "doesn't add same entity twice" do
      group_a = new_group_a
      e_a1 = new_entity_with_a
      group_a.handle_entity_silently(e_a1)
      assert_contains(group_a, [e_a1])
    end

    it "enumerates group" do
      group_a, e_a1 = new_group_a_w_e

      group_a.each do |entity|
        entity
      end

      group_a.size.should eq 1
      group_a.first.should be e_a1
    end

    it "returns enumerable" do
      group_a, e_a1 = new_group_a_w_e
      group_a.first.should eq e_a1
    end

    describe "when entity doesn't match anymore" do
      it "removes entity" do
        group_a, e_a1 = new_group_a_w_e
        e_a1.del_a
        group_a.handle_entity_silently(e_a1)
        assert_not_contains(group_a, e_a1)
      end
    end
  end

  describe "when entity is not enabled" do
    it "doesn't add entity" do
      group_a, e_a1 = new_group_a_w_e
      e_a1.internal_destroy!
      group_a.handle_entity_silently(e_a1)
      assert_not_contains(group_a, e_a1)
    end
  end

  it "doesn't add entity when not matching" do
    group_a = new_group_a
    e = new_entity
    e.add_b
    group_a.handle_entity_silently(e)
    assert_not_contains(group_a, e)
  end

  it "gets null when single entity does not exist" do
    group_a = new_group_a
    group_a.get_single_entity.should be_nil
  end

  it "gets single entity" do
    group_a, e_a1 = new_group_a_w_e
    group_a.get_single_entity.should be e_a1
  end

  it "throws when attempting to get single entity and multiple matching entities exist" do
    group_a, _ = new_group_a_w_e
    e_a2 = new_entity
    e_a2.add_a
    group_a.handle_entity_silently(e_a2)
    group_a.size.should eq 2

    expect_raises Entitas::Group::Error::SingleEntity do
      group_a.get_single_entity
    end
  end

  describe "events" do
    it "dispatches OnEntityAdded when matching entity added" do
      did_dispatch = 0
      group_a = new_group_a

      e_a1 = new_entity
      e_a1.add_a
      comp = e_a1.a

      group_a.on_entity_added do |event|
        did_dispatch += 1
        event.group.should be group_a
        event.entity.should be e_a1
        event.index.should eq Entitas::Component::Index::A.value
        event.component.should eq comp
      end

      group_a.on_entity_removed { fail("Should not trigger #on_entity_removed") }
      group_a.on_entity_updated { fail("Should not trigger #on_entity_updated") }

      group_a.handle_add_ea(e_a1)
      did_dispatch.should eq 1
    end

    it "doesn't dispatches OnEntityAdded when matching entity already has been added" do
      group_a, e_a1 = new_group_a_w_e

      group_a.on_entity_added { fail("Should not trigger #on_entity_added") }
      group_a.on_entity_removed { fail("Should not trigger #on_entity_removed") }
      group_a.on_entity_updated { fail("Should not trigger #on_entity_updated") }

      group_a.handle_add_ea(e_a1)
    end

    it "doesn't dispatches OnEntityAdded when entity is not matching" do
      group_a, _ = new_group_a_w_e

      e_b1 = new_entity
      e_b1.add_b

      group_a.on_entity_added { fail("Should not trigger #on_entity_added") }
      group_a.on_entity_removed { fail("Should not trigger #on_entity_removed") }
      group_a.on_entity_updated { fail("Should not trigger #on_entity_updated") }

      group_a.handle_add_eb(e_b1)
    end

    it "dispatches OnEntityRemoved when entity got removed" do
      did_dispatch = 0
      group_a, e_a1 = new_group_a_w_e
      comp = e_a1.a
      group_a.on_entity_added { true.should be_false }
      group_a.on_entity_removed do |event|
        did_dispatch += 1
        event.group.should be group_a
        event.entity.should be e_a1
        event.index.should eq Entitas::Component::Index::A.value
        event.component.should eq comp
      end
      group_a.on_entity_updated { fail("Should not trigger #on_entity_updated") }

      e_a1.del_a

      group_a.handle_remove_ea(e_a1, comp)

      did_dispatch.should eq 1
    end

    it "doesn't dispatch OnEntityRemoved when entity didn't get removed" do
      group_a, e_a1 = new_group_a_w_e
      comp = e_a1.a
      group_a.on_entity_removed { true.should be_false }
      group_a.handle_remove_ea(e_a1, comp)
    end

    it "dispatches OnEntityRemoved, OnEntityAdded and OnEntityUpdated when updating" do
      group_a, e_a1 = new_group_a_w_e
      component_a = e_a1.a
      removed = 0
      added = 0
      updated = 0
      new_component_a = A.new

      group_a.on_entity_removed do |event|
        removed += 1
        event.group.should be group_a
        event.entity.should be e_a1
        event.index.should eq Entitas::Component::Index::A.value
        event.component.should be component_a
      end

      group_a.on_entity_added do |event|
        added += 1
        event.group.should be group_a
        event.entity.should be e_a1
        event.index.should eq Entitas::Component::Index::A.value
        event.component.should be new_component_a
      end

      group_a.on_entity_updated do |event|
        updated += 1
        event.group.should be group_a
        event.entity.should be e_a1
        event.index.should eq Entitas::Component::Index::A.value
        event.prev_component.should be component_a
        event.new_component.should be new_component_a
      end

      group_a.update_ea(e_a1, component_a, new_component_a)

      removed.should eq 1
      added.should eq 1
      updated.should eq 1
    end

    it "doesn't dispatch OnEntityRemoved and OnEntityAdded when updating when group doesn't contain entity" do
      group_a = new_group_a
      e_a1 = new_entity
      e_a1.add_a

      group_a.on_entity_added { true.should be_false }
      group_a.on_entity_removed { true.should be_false }
      group_a.on_entity_updated { true.should be_false }

      group_a.update_ea(e_a1, e_a1.a, A.new)
    end

    it "removes all event handlers" do
      group_a = new_group_a
      e_a1 = new_entity
      e_a1.add_a

      group_a.on_entity_added { true.should be_false }
      group_a.on_entity_removed { true.should be_false }
      group_a.on_entity_updated { true.should be_false }

      group_a.remove_all_event_handlers

      group_a.handle_add_ea(e_a1)

      c_a = e_a1.a
      e_a1.del_a
      group_a.handle_remove_ea(e_a1, c_a)

      e_a1.add_a
      group_a.update_ea(e_a1, e_a1.a, c_a)
    end
  end

  describe "internal caching" do
    describe "#get_entities" do
      it "gets cached entities" do
        group_a, _, cache = new_group_with_cache
        group_a.get_entities.should be cache
      end

      it "updates cache when adding a new matching entity" do
        group_a, _, cache = new_group_with_cache
        e_a2 = new_entity
        e_a2.add_a
        group_a.handle_silently(e_a2)

        group_a.get_entities.should_not be cache
        group_a.get_entities.should_not eq cache
      end

      it "doesn't update cache when attempting to add a not matching entity" do
        group_a, _, cache = new_group_with_cache
        group_a.handle_silently(new_entity)
        group_a.get_entities.should be cache
      end

      it "updates cache when removing an entity" do
        group_a, e_a1, cache = new_group_with_cache
        e_a1.del_a
        group_a.handle_silently(e_a1)
        group_a.get_entities.should_not be cache
        group_a.get_entities.should_not eq cache
      end

      it "doesn't update cache when attempting to remove an entity that wasn't added before" do
        group_a, _, cache = new_group_with_cache
        e_a2 = new_entity
        e_a2.add_a
        e_a2.del_a
        group_a.handle_silently(e_a2)

        group_a.get_entities.should be cache
      end

      it "doesn't update cache when updating an entity" do
        group_a, e_a1, cache = new_group_with_cache
        group_a.update_ea(e_a1, e_a1.a, A.new)
        group_a.get_entities.should be cache
      end
    end

    describe "#get_single_entity" do
      it "gets cached singleEntities" do
        group_a, _, cache = new_group_with_single_cache
        group_a.get_single_entity.should be cache
      end

      it "updates cache when new single entity was added" do
        group_a, e_a1, cache = new_group_with_single_cache
        e_a1.del_a
        e_a2 = new_entity
        e_a2.add_a
        group_a.handle_silently(e_a1)
        group_a.handle_silently(e_a2)
        group_a.get_single_entity.should_not be cache
        group_a.get_single_entity.should be e_a2
      end

      it "updates cache when single entity is removed" do
        group_a, e_a1, cache = new_group_with_single_cache
        e_a1.del_a
        group_a.handle_silently(e_a1)
        group_a.get_single_entity.should_not be cache
      end

      it "doesn't update cache when single entity is updated" do
        group_a, e_a1, cache = new_group_with_single_cache
        group_a.update_ea(e_a1, e_a1.a, A.new)
        group_a.get_single_entity.should be cache
      end
    end
  end

  describe "reference counting" do
    it "retains matched entity" do
      e = new_entity
      e.add_a

      e.retain_count.should eq 0
      new_group_a.handle_silently(e)
      e.retain_count.should eq 1
    end

    it "releases removed entity" do
      e = new_entity
      e.add_a
      group = new_group_a
      e.retain_count.should eq 0
      group.handle_silently(e)
      e.retain_count.should eq 1
      e.del_a
      group.handle_silently(e)
      e.retain_count.should eq 0
    end

    it "invalidates entitiesCache (silent mode)" do
      did_execute = 0
      group = new_group_a
      e = new_entity
      e.add_a
      e.on_entity_released do
        did_execute += 1
        group.get_entities.should be_empty
      end

      group.handle_silently(e)
      group.get_entities
      e.del_a
      group.handle_silently(e)
      did_execute.should eq 1
    end

    it "invalidates entitiesCache" do
      did_execute = 0
      group = new_group_a
      e = new_entity
      e.add_a
      e.on_entity_released do
        did_execute += 1
        group.get_entities.should be_empty
      end

      group.handle_add_ea(e)
      group.get_entities
      e.del_a
      group.handle_remove_ea(e, A.new)
      did_execute.should eq 1
    end

    it "invalidates singleEntityCache (silent mode)" do
      did_execute = 0
      group = new_group_a
      e = new_entity
      e.add_a
      e.on_entity_released do
        did_execute += 1
        group.get_single_entity.should be_nil
      end

      group.handle_silently(e)
      group.get_single_entity
      e.del_a
      group.handle_silently(e)
      did_execute.should eq 1
    end

    it "invalidates singleEntityCache" do
      did_execute = 0
      group = new_group_a
      e = new_entity
      e.add_a
      e.on_entity_released do
        did_execute += 1
        group.get_single_entity.should be_nil
      end

      group.handle_add_ea(e)
      group.get_single_entity
      e.del_a
      group.handle_remove_ea(e, A.new)
      did_execute.should eq 1
    end

    it "retains entity until after event handlers were called" do
      did_execute = 0
      group = new_group_a
      e = new_entity
      e.add_a
      group.on_entity_removed do |event|
        did_execute += 1
        event.entity.retain_count.should eq 1
      end

      group.handle_add_ea(e)
      group.get_entities
      e.del_a
      group.handle_remove_ea(e, A.new)
      did_execute.should eq 1
      e.retain_count.should eq 0
    end
  end

  it "can to_s" do
    m = Entitas::Matcher.all_of(
      Entitas::Matcher.all_of(A),
      Entitas::Matcher.all_of(B)
    )
    group = Entitas::Group.new(m)
    group.to_s.should eq "Group(AllOf(0, 1))"
  end
end
