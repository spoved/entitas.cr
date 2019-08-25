require "../spec_helper"

private def ctx_and_entities
  ctx = new_context
  eab1 = ctx.create_entity
  eab1.add_a
  eab1.add_b

  eab2 = ctx.create_entity
  eab2.add_a
  eab2.add_b

  ea = ctx.create_entity
  ea.add_a

  {ctx, eab1, eab2, ea}
end

private def entity_index(ctx)
  group = ctx.get_group(Entitas::Matcher.all_of(A))
  Entitas::PrimaryEntityIndex(String).new("TestIndex", group, ->(entity : Entitas::Entity, component : Entitas::Component?) {
    (component.nil? ? entity.get_component_name_age.name : component.as(NameAge).name).as(String)
  })
end

describe Entitas::Context do
  describe "when created" do
    it "increments creation index" do
      ctx = new_context
      ctx.create_entity.creation_index.should eq 0
      ctx.create_entity.creation_index.should eq 1
    end

    it "starts with given creation_index" do
      ctx = TestContext.new(creation_index: 42, context_info: new_context_info)
      ctx.create_entity.creation_index.should eq 42
      ctx.create_entity.creation_index.should eq 43
    end

    it "has no entities when no entities were created" do
      new_context.get_entities.should be_empty
    end

    it "gets total entity count" do
      new_context.size.should eq 0
    end

    it "creates entity" do
      ctx = new_context
      e = ctx.create_entity
      e.should_not be_nil
      e.should be_a(TestEntity)
      e.total_components.should eq ctx.total_components
      e.enabled?.should be_true
    end

    it "has default Context::Info" do
      ctx = TestContext.new
      ctx.info.name.should eq "TestContext"
      ctx.info.component_names.size.should eq 6
      ctx.total_components.times do |i|
        ctx.info.component_names[i].should eq "Index #{i}"
      end
    end

    it "creates component pools" do
      ctx = new_context
      ctx.component_pools.should_not be_nil
      ctx.component_pools.size.should eq ctx.total_components
    end

    it "creates entity with component pools" do
      ctx = new_context
      e = ctx.create_entity
      e.component_pools.should be ctx.component_pools
    end

    it "can to_s" do
      new_context.to_s.should eq "TestContext"
    end

    describe "when Context::Info set" do
      context_info = new_context_info
      ctx = TestContext.new(context_info: context_info)

      it "has custom context info" do
        ctx.context_info.should be context_info
      end

      it "creates entity with same Context::Info" do
        ctx.create_entity.context_info.should be context_info
      end

      it "throws when component_names is not same length as total_components" do
        context = Entitas::Context::Info.new("TestContext", ["A", "B"], [A, B, C])
        expect_raises Entitas::Context::Error::Info do
          TestContext.new(context_info: context)
        end
      end
    end

    describe "when entity created" do
      it "gets total entity count" do
        ctx, _ = context_with_entity
        ctx.size.should eq 1
      end

      it "has entities that were created with #create_entity" do
        ctx, e = context_with_entity
        ctx.has_entity?(e).should be_true
      end

      it "returns all created entities" do
        ctx, e = context_with_entity
        e_two = ctx.create_entity
        entities = ctx.get_entities
        entities.size.should eq 2
        entities.includes?(e)
        entities.includes?(e_two)
      end

      it "destroys entity and removes it" do
        ctx, e = context_with_entity
        e.destroy!
        ctx.has_entity?(e)
        ctx.count.should eq 0
        ctx.get_entities.should be_empty
      end

      it "destroys an entity and removes all its components" do
        _, e = context_with_entity
        e.destroy!
        e.get_components.should be_empty
      end

      it "removes OnDestroyEntity handler" do
        did_destroy = 0
        ctx, e = context_with_entity
        ctx.on_entity_will_be_destroyed { did_destroy += 1 }
        e.destroy!

        ctx.create_entity.destroy!
        did_destroy.should eq 2
      end

      it "destroys all entities" do
        ctx, _ = context_with_entity
        ctx.create_entity
        ctx.destroy_all_entities
      end

      it "throws when destroying all entities and there are still entities retained" do
        ctx = new_context
        ctx.create_entity.retain("something")
        expect_raises Entitas::Context::Error::StillHasRetainedEntities do
          ctx.destroy_all_entities
        end
      end
    end

    describe "internal caching" do
      it "caches entities" do
        ctx, _ = context_with_entity
        entities = ctx.get_entities
        ctx.get_entities.should eq entities
      end

      it "updates entities cache when creating an entity" do
        ctx, _ = context_with_entity
        entities = ctx.get_entities
        ctx.create_entity
        ctx.get_entities.should_not eq entities
      end

      it "updates entities cache when destroying an entity" do
        ctx, e = context_with_entity
        entities = ctx.get_entities
        e.destroy
        ctx.get_entities.should_not eq entities
      end
    end

    describe "events" do
      it "dispatches OnEntityCreated when creating a new entity" do
        did_dispatch = 0
        ctx = new_context

        event_entity : ::Entitas::Entity? = nil
        ctx.on_entity_created do |event|
          did_dispatch += 1
          event_entity = event.entity
        end

        e = ctx.create_entity
        did_dispatch.should eq 1
        event_entity.should be e
      end

      it "dispatches OnEntityWillBeDestroyed when destroying an entity" do
        did_dispatch = 0
        ctx, e = context_with_entity
        ctx.on_entity_will_be_destroyed do |event|
          did_dispatch += 1
          event.context.should be ctx
          event.entity.should be e
          event.entity.has_a?.should be_true
          event.entity.enabled?.should be_true
          event.context.get_entities.size.should eq 0
        end

        ctx.get_entities
        e.destroy
        did_dispatch.should eq 1
      end

      it "dispatches OnEntityDestroyed when destroying an entity" do
        did_dispatch = 0
        ctx, e = context_with_entity
        ctx.on_entity_destroyed do |event|
          did_dispatch += 1
          event.context.should be ctx
          event.entity.should be e
          event.entity.has_a?.should be_false
          event.entity.enabled?.should be_false
        end

        e.destroy
        did_dispatch.should eq 1
      end

      it "entity is released after OnEntityDestroyed" do
        did_dispatch = 0
        ctx, e = context_with_entity
        ctx.on_entity_destroyed do |event|
          did_dispatch += 1
          event.entity.retain_count.should eq 1
          new_e = ctx.create_entity
          new_e.should_not be_nil
          new_e.should_not be event.entity
        end

        e.destroy
        reused_entity = ctx.create_entity
        reused_entity.should be e
        did_dispatch.should eq 1
      end

      it "throws if entity is released before it is destroyed" do
        ctx, e = context_with_entity
        e.retain_count.should eq 1

        expect_raises Entitas::Entity::Error::IsNotDestroyedException do
          e.release(ctx)
        end
      end

      it "dispatches OnGroupCreated when creating a new group" do
        did_dispatch = 0
        ctx, _ = context_with_entity

        event_group : Entitas::Group? = nil

        ctx.on_group_created do |event|
          did_dispatch += 1
          event.context.should be ctx
          event_group = event.group
        end

        group = ctx.get_group(Entitas::Matcher.all_of(A))
        did_dispatch.should eq 1
        event_group.should be group
      end

      it "doesn't dispatch OnGroupCreated when group alredy exists" do
        ctx, _ = context_with_entity
        ctx.get_group(Entitas::Matcher.all_of(A))
        ctx.on_group_created { fail "Should not be called" }
        ctx.get_group(Entitas::Matcher.all_of(A))
      end

      it "removes all external delegates when destroying an entity" do
        ctx = new_context
        e = ctx.create_entity

        e.on_component_added { false.should be_true }
        e.on_component_removed { false.should be_true }
        e.on_component_replaced { false.should be_true }

        e.destroy

        e2 = ctx.create_entity
        e2.should be e
        e2.add_a
        e2.replace_component(A.new)
        e2.remove_component(TestContext::Index::A.value)
      end

      it "will not remove external delegates for OnEntityReleased" do
        ctx = new_context
        e = ctx.create_entity
        did_release = 0
        e.on_entity_released { did_release += 1 }
        e.destroy
        did_release.should eq 1
      end

      it "removes all external delegates from OnEntityReleased when after being dispatched" do
        _, e = context_with_entity
        did_release = 0
        e.on_entity_released { did_release += 1 }
        e.destroy
        obj = "owner"
        e.retain(obj)
        e.release(obj)
        did_release.should eq 1
      end

      it "removes all external delegates from OnEntityReleased after being dispatched (when delayed release)" do
        _, e = context_with_entity
        did_release = 0
        obj = "owner"

        e.on_entity_released { did_release += 1 }

        e.retain(obj)
        e.destroy
        did_release.should eq 0

        e.release(obj)
        did_release.should eq 1

        e.retain(obj)
        e.release(obj)
        did_release.should eq 1
      end
    end

    describe "entity pool" do
      it "gets entity from object pool" do
        _, e = context_with_entity
        e.should_not be_nil
        e.should be_a TestEntity
      end

      it "destroys entity when pushing back to object pool" do
        _, e = context_with_entity
        e.has_a?.should be_true
        e.destroy!
        e.has_a?.should be_false
      end

      it "returns pushed entity" do
        ctx, e = context_with_entity
        e.has_a?.should be_true
        e.destroy!

        entity = ctx.create_entity
        entity.has_a?.should be_false
        entity.should be e
      end

      it "only returns released entities" do
        ctx, e1 = context_with_entity
        owner = "owner"
        e1.retain(owner)
        e1.destroy

        e2 = ctx.create_entity
        e2.should_not be e1

        e1.release owner

        e3 = ctx.create_entity
        e3.should be e1
      end

      it "returns a new entity" do
        ctx, e1 = context_with_entity
        e1.destroy
        ctx.create_entity.should be e1

        e2 = ctx.create_entity
        e2.has_a?.should be_false
        e2.should_not be e1
      end

      it "sets up entity from pool" do
        ctx, e = context_with_entity
        c_index = e.creation_index
        e.destroy
        g = ctx.get_group(Entitas::Matcher.all_of(A))

        e = ctx.create_entity

        e.creation_index.should eq (c_index + 1)
        e.enabled?.should be_true

        e.add_a
        g.get_entities.should contain(e)
      end

      describe "when entity gets destroyed" do
        it "throws when adding component" do
          _, e = context_with_entity
          e.has_a?.should be_true
          e.destroy!

          expect_raises Entitas::Entity::Error::IsNotEnabled do
            e.add_a
          end
        end

        it "throws when removing component" do
          _, e = context_with_entity
          e.has_a?.should be_true
          e.destroy!

          expect_raises Entitas::Entity::Error::IsNotEnabled do
            e.del_a
          end
        end

        it "throws when replacing component" do
          _, e = context_with_entity
          e.has_a?.should be_true
          e.destroy!

          expect_raises Entitas::Entity::Error::IsNotEnabled do
            e.replace_component(A.new)
          end
        end

        it "throws when replacing component with null" do
          _, e = context_with_entity
          e.has_a?.should be_true
          e.destroy!

          expect_raises Entitas::Entity::Error::IsNotEnabled do
            e.replace_component(Entitas::Component::Index::A, nil)
          end
        end

        it "throws when attempting to destroy again" do
          _, e = context_with_entity
          e.has_a?.should be_true
          e.destroy!

          expect_raises Entitas::Entity::Error::IsNotEnabled do
            e.destroy!
          end
        end
      end
    end

    describe "groups" do
      it "gets empty group for matcher when no entities were created" do
        g = new_context.get_group(Entitas::Matcher.all_of(A))
        g.should_not be_nil
        g.get_entities.should be_empty
      end

      describe "when entities created" do
        matcher_ab = Entitas::Matcher.all_of(A, B)

        it "gets group with matching entities" do
          ctx, eab1, eab2, _ = ctx_and_entities
          g = ctx.get_group(matcher_ab)
          g.size.should eq 2
          g.includes?(eab1)
          g.includes?(eab2)
        end

        it "gets cached group" do
          ctx, _, _, _ = ctx_and_entities
          ctx.get_group(matcher_ab).should be ctx.get_group(matcher_ab)
        end

        it "cached group contains newly created matching entity" do
          ctx, _, _, ea = ctx_and_entities
          g = ctx.get_group(matcher_ab)
          ea.add_b
          g.get_entities.includes?(ea).should be_true
        end

        it "cached group doesn't contain entity which are not matching anymore" do
          ctx, eab1, _, _ = ctx_and_entities
          g = ctx.get_group(matcher_ab)
          eab1.del_a
          g.get_entities.includes?(eab1).should be_false
        end

        it "removes destroyed entity" do
          ctx, eab1, _, _ = ctx_and_entities
          g = ctx.get_group(matcher_ab)
          eab1.destroy!
          g.get_entities.includes?(eab1).should be_false
        end

        it "group dispatches OnEntityRemoved and OnEntityAdded when replacing components" do
          ctx, eab1, _, _ = ctx_and_entities
          g = ctx.get_group(matcher_ab)

          eab1_comp_a = eab1.a
          did_dispatch_removed = 0
          did_dispatch_added = 0
          comp_a = A.new

          g.on_entity_removed do |event|
            event.group.should be g
            event.entity.should be eab1
            event.index.should eq Entitas::Component::Index::A.value
            event.component.should be eab1_comp_a
            did_dispatch_removed += 1
          end

          g.on_entity_added do |event|
            event.group.should be g
            event.entity.should be eab1
            event.index.should eq Entitas::Component::Index::A.value
            event.component.should be comp_a
            did_dispatch_added += 1
          end

          eab1.replace_a(comp_a)
          did_dispatch_removed.should eq 1
          did_dispatch_added.should eq 1
        end

        it "group dispatches OnEntityUpdated with previous and current component when replacing a component" do
          updated = 0

          ctx, eab1, _, _ = ctx_and_entities
          prev_comp = eab1.a
          new_comp = A.new

          g = ctx.get_group(matcher_ab)

          g.on_entity_updated do |event|
            event.group.should be g
            event.entity.should be eab1
            event.index.should eq Entitas::Component::Index::A.value
            event.prev_component.should be prev_comp
            event.new_component.should be new_comp
            updated += 1
          end

          eab1.replace_component Entitas::Component::Index::A, new_comp
          updated.should eq 1
        end

        it "group with matcher NoneOf doesn't dispatch OnEntityAdded when destroying entity" do
          ctx = new_context
          e = ctx.create_entity.add_a.add_b
          matcher = Entitas::Matcher.all_of(B).all_of(A)
          g = ctx.get_group(matcher)
          g.on_entity_added { fail "Should not be called" }
          e.destroy!
        end

        describe "event timing" do
          it "dispatches group.OnEntityAdded events after all groups are updated" do
            ctx = new_context
            group_a = ctx.get_group Entitas::Matcher.all_of(A, B)
            group_b = ctx.get_group Entitas::Matcher.all_of(B)

            group_a.on_entity_added do
              group_b.size.should eq 1
            end

            ctx.create_entity.add_a.add_b
          end

          it "dispatches group.OnEntityRemoved events after all groups are updated" do
            ctx = new_context
            group_b = ctx.get_group Entitas::Matcher.all_of(B)
            group_ab = ctx.get_group Entitas::Matcher.all_of(A, B)

            group_b.on_entity_removed do
              group_ab.size.should eq 0
            end

            ctx.create_entity.add_a.add_b.del_b
          end
        end
      end
    end

    describe "entity index" do
      it "throws when EntityIndex for key doesn't exist" do
        expect_raises Entitas::EntityIndex::Error::DoesNotExist do
          ctx = new_context
          ctx.get_entity_index "unknown_index"
        end
      end

      it "adds and EntityIndex" do
        ctx = new_context
        index = entity_index(ctx)
        ctx.add_entity_index(index)
        ctx.get_entity_index(index.name).should be index
      end

      it "throws when adding an EntityIndex with same name" do
        ctx = new_context
        index = entity_index(ctx)
        ctx.add_entity_index(index)
        expect_raises Entitas::EntityIndex::Error::AlreadyExists do
          ctx.add_entity_index(index)
        end
      end
    end

    describe "reset" do
      describe "context" do
        it "resets creation index" do
          ctx = new_context
          ctx.reset_creation_index
          ctx.create_entity.creation_index.should eq 0
        end

        describe "removes all event handlers" do
          it "removes OnEntityCreated" do
            ctx = new_context
            ctx.on_entity_created { fail "Should not be called" }
            ctx.remove_all_event_handlers
            ctx.create_entity
          end

          it "removes OnEntityWillBeDestroyed" do
            ctx = new_context
            ctx.on_entity_will_be_destroyed { fail "Should not be called" }
            ctx.remove_all_event_handlers
            ctx.create_entity.destroy!
          end

          it "removes OnEntityDestroyed" do
            ctx = new_context
            ctx.on_entity_destroyed { fail "Should not be called" }
            ctx.remove_all_event_handlers
            ctx.create_entity.destroy!
          end

          it "removes OnGroupCreated" do
            ctx = new_context
            ctx.on_group_created { fail "Should not be called" }
            ctx.remove_all_event_handlers
            ctx.get_group(Entitas::Matcher.all_of(A))
          end
        end
      end

      describe "component pools" do
        it "cant add component not in context" do
          ctx = InputContext.new
          expect_raises Entitas::Entity::Error::DoesNotHaveComponent do
            ctx.create_entity.add_a
          end
        end

        it "clears all component pools" do
          ctx, e = context_with_entity
          e.add_b
          e.del_a
          e.del_b

          ctx.component_pools[Entitas::Component::Index::A.value].size.should eq 1
          ctx.component_pools[Entitas::Component::Index::B.value].size.should eq 1

          ctx.clear_component_pools

          ctx.component_pools[Entitas::Component::Index::A.value].size.should eq 0
          ctx.component_pools[Entitas::Component::Index::B.value].size.should eq 0
        end

        it "clears a specific component pool" do
          ctx, e = context_with_entity
          e.add_b
          e.del_a
          e.del_b

          ctx.clear_component_pool(B)
          ctx.component_pools[Entitas::Component::Index::A.value].size.should eq 1
          ctx.component_pools[Entitas::Component::Index::B.value].size.should eq 0
        end

        it "only clears existing component pool" do
          ctx, e = context_with_entity
          e.add_b
          e.del_a
          e.del_b
          ctx.clear_component_pool(C)
        end
      end
    end

    describe "entitas cache" do
      it "pops new list from list pool" do
        ctx = new_context
        group_a = ctx.get_group(Entitas::Matcher.all_of(A))
        group_ab = ctx.get_group(Entitas::Matcher.any_of(A, B))
        group_abc = ctx.get_group(Entitas::Matcher.any_of(A, B, C))

        did_execute = 0

        group_a.on_entity_added do |event|
          did_execute += 1
          entity = event.entity
          entity.del_a
        end

        group_ab.on_entity_added do |_|
          did_execute += 1
        end

        group_abc.on_entity_added do |_|
          did_execute += 1
        end

        ctx.create_entity.add_a

        did_execute.should eq 3
      end
    end

    describe "unique components" do
      it "should have none by default" do
        ctx = new_context
        ctx.unique_comp?.should be_falsey
      end

      it "should allow setting of the component" do
        ctx = new_context
        comp = UniqueComp.new
        ctx.unique_comp = comp
        ctx.unique_comp?.should be_true
        ctx.unique_comp.should be comp
      end

      describe "with a pre-existing component" do
        it "can replace" do
          ctx = new_context
          comp = UniqueComp.new
          ctx.unique_comp = comp
          ctx.unique_comp?.should be_true
          ctx.unique_comp.should be comp

          comp2 = UniqueComp.new
          ctx.replace_unique_comp comp2
          ctx.unique_comp.should be comp2
        end

        it "raises an error when setting component " do
          ctx = new_context
          comp = UniqueComp.new
          ctx.unique_comp = comp
          comp2 = UniqueComp.new
          expect_raises Entitas::Context::Error do
            ctx.unique_comp = comp2
          end
        end

        it "raises an error when creating an entity with another unique component" do
          ctx = new_context
          comp = UniqueComp.new
          ctx.unique_comp = comp
          comp2 = UniqueComp.new

          entity = ctx.create_entity
          entity.add_component(comp2)

          expect_raises Entitas::Group::Error::SingleEntity do
            ctx.unique_comp
          end
        end
      end
    end
  end
end
