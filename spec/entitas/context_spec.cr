require "../spec_helper"

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
      ctx.info.component_names.size.should eq 5
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
        context = Entitas::Context::Info.new("TestContext", ["A", "B"])
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

      # TODO: dispatches OnGroupCreated when creating a new group
      # TODO: doesn't dispatch OnGroupCreated when group alredy exists

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
        # ctx, e = context_with_entity
        # c_index = e.creation_index
        # e.destroy
        # TODO: FINISH GROUPS
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
      # TODO
    end

    describe "entity index" do
      # TODO
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
            ctx.on_entity_created { true.should be_false }
            ctx.remove_all_event_handlers
            ctx.create_entity
          end

          it "removes OnEntityWillBeDestroyed" do
            ctx = new_context
            ctx.on_entity_will_be_destroyed { true.should be_false }
            ctx.remove_all_event_handlers
            ctx.create_entity.destroy!
          end

          it "removes OnEntityDestroyed" do
            ctx = new_context
            ctx.on_entity_destroyed { true.should be_false }
            ctx.remove_all_event_handlers
            ctx.create_entity.destroy!
          end

          it "removes OnGroupCreated" do
            # TODO finish
          end
        end
      end

      describe "component pools" do
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
      end
    end
  end
end
