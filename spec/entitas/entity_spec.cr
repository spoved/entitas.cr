require "../spec_helper"

describe Entitas::Entity do
  describe "destroyed" do
    it "raises IsNotEnabled when adding a component" do
      entity = new_entity
      entity.internal_destroy!
      expect_raises Entitas::Entity::Error::IsNotEnabled do
        entity.add_a
      end
    end

    it "wont raise IsNotEnabled with context index" do
      entity = new_entity
      entity.add_a
    end
  end

  describe "when created" do
    describe "initial state" do
      it "has default context info" do
        entity = new_entity
        entity.context_info.name.should eq "No Context"
        entity.context_info.component_names.size.should eq Entitas::Component::TOTAL_COMPONENTS
      end

      it "reactivates after being destroyed" do
        entity = new_entity
        entity.enabled?.should be_truthy

        entity.internal_destroy!
        entity.enabled?.should be_falsey

        entity.reactivate(42)
        entity.enabled?.should be_truthy
      end

      it "throws when attempting to get component at index which hasn't been added" do
        entity = new_entity
        expect_raises Entitas::Entity::Error::DoesNotHaveComponent do
          entity.a
        end
      end

      it "gets total components count when empty" do
        new_entity.total_components.should eq Entitas::Component::TOTAL_COMPONENTS
      end

      it "gets empty array of components when no components were added" do
        new_entity.get_components.should be_empty
      end

      it "gets empty array of component indices when no components were added" do
        new_entity.get_component_indices.should be_empty
      end

      it "doesn't have component at index when no component was added" do
        new_entity.has_a?.should be_falsey
      end

      it "doesn't have components at indices when no components were added" do
        new_entity.has_components?([Entitas::Component::Index::A]).should be_falsey
      end

      it "doesn't have any components at indices when no components were added" do
        new_entity.has_any_component?([Entitas::Component::Index::A]).should be_falsey
      end

      it "adds a component" do
        entity = new_entity
        entity.add_a
        entity.has_a?.should be_truthy
        entity.a.should be_a A
      end

      it "throws when attempting to remove a component at index which hasn't been added" do
        expect_raises Entitas::Entity::Error::DoesNotHaveComponent do
          new_entity.del_a
        end
      end

      it "replacing a non existing component adds component" do
        component = A.new
        entity = new_entity
        entity.has_a?.should be_falsey
        entity.replace_component(component)
        entity.has_a?.should be_truthy
        entity.a.should be component
      end
    end

    describe "when component added" do
      it "throws when adding a component at the same index twice" do
        entity = new_entity_with_a
        expect_raises Entitas::Entity::Error::AlreadyHasComponent do
          entity.add_a
        end
      end

      it "removes a component at index" do
        entity = new_entity_with_a
        entity.del_a
        entity.has_a?.should be_falsey
      end

      it "replaces existing component" do
        entity = new_entity_with_a
        orig_comp = entity.a
        new_comp = A.new
        entity.replace_a(new_comp)
        entity.a.should_not be orig_comp
        entity.a.should be new_comp
      end

      it "doesn't have components at indices when not all components were added" do
        new_entity_with_a.has_components?([
          Entitas::Component::Index::A,
          Entitas::Component::Index::B,
        ]).should be_falsey
      end

      it "has any components at indices when any component was added" do
        new_entity_with_a.has_any_component?([
          Entitas::Component::Index::A,
          Entitas::Component::Index::B,
        ]).should be_truthy
      end

      describe "when adding another component" do
        it "gets all components" do
          comps = new_entity_with_ab.get_components
          comps.size.should eq 2
          comps.first.should be_a(A)
          comps.last.should be_a(B)
        end
        it "has other component" do
          new_entity_with_ab.has_b?.should be_truthy
        end

        it "has components at indices when all components were added" do
          new_entity_with_ab.has_components?([
            Entitas::Component::Index::A,
            Entitas::Component::Index::B,
          ]).should be_true
        end

        it "removes all components" do
          entity = new_entity_with_a
          entity.remove_all_components!
          entity.has_a?.should be_falsey
          entity.has_b?.should be_falsey
          entity.get_components.should be_empty
          entity.get_component_indices.should be_empty
        end
      end
    end

    describe "component pool" do
      it "gets component context" do
        entity = new_entity
        pool = entity.component_pool(Entitas::Component::Index::A)
        pool.should be_empty
      end

      it "gets same component context instance" do
        entity = new_entity
        pool = entity.component_pool(Entitas::Component::Index::A)
        pool.should be entity.component_pool(Entitas::Component::Index::A)
      end

      it "pushes component to component_pool when removed" do
        entity = new_entity

        entity.add_a
        component = entity.a
        component.should be_a A

        pool = entity.component_pool(Entitas::Component::Index::A)
        pool.should be_empty

        entity.del_a
        pool.should_not be_empty
        pool.first.should be component
      end

      it "creates new component when component_pool is empty" do
        entity = new_entity
        component = entity.create_component(A)
        component.should be_a A
      end

      it "gets pooled component when component_pool is not empty" do
        entity = new_entity
        entity.add_a
        component = entity.a
        component.should be_a A

        entity.del_a
        entity.component_pool(Entitas::Component::Index::A).should_not be_empty

        new_component = entity.create_component(A)
        new_component.should be component
      end
    end

    describe "events" do
      it "dispatches OnComponentAdded when adding a component" do
        entity = new_entity
        did_dispatch = 0
        component = A.new

        entity.on_component_added do |event|
          did_dispatch += 1
          event.entity.should be entity
          event.index.should eq Entitas::Component::Index::A.value
          event.component.should be component
        end

        entity.on_component_removed { true.should eq false }
        entity.on_component_replaced { true.should eq false }

        entity.add_component(component)
        did_dispatch.should eq 1
      end

      it "dispatches OnComponentRemoved when removing a component" do
        entity = new_entity_with_a
        did_dispatch = 0
        component = entity.a

        entity.on_component_removed do |event|
          did_dispatch += 1
          event.entity.should be entity
          event.index.should eq Entitas::Component::Index::A.value
          event.component.should be component
        end

        entity.on_component_added { true.should eq false }
        entity.on_component_replaced { true.should eq false }

        entity.del_a
        did_dispatch.should eq 1
      end

      it "dispatches OnComponentRemoved before pushing component to context" do
        entity = new_entity_with_a
        component = entity.a

        entity.on_component_removed do
          new_component = entity.create_component(A)
          component.should_not be new_component
        end

        entity.del_a
      end

      it "dispatches OnComponentReplaced when replacing a component" do
        entity = new_entity_with_a
        did_dispatch = 0
        component = entity.a
        new_component = A.new

        entity.on_component_replaced do |event|
          did_dispatch += 1
          event.entity.should be entity
          event.index.should eq Entitas::Component::Index::A.value
          event.prev_component.should be component
          event.new_component.should be new_component
        end

        entity.replace_a(new_component)
        did_dispatch.should eq 1
      end

      it "provides previous and new component OnComponentReplaced when replacing with different component" do
        entity = new_entity
        did_dispatch = 0
        prev_component = A.new
        new_component = A.new

        entity.on_component_replaced do |event|
          did_dispatch += 1
          event.entity.should be entity
          event.index.should eq Entitas::Component::Index::A.value
          event.prev_component.should be prev_component
          event.new_component.should be new_component
        end

        entity.add_component(prev_component)
        entity.replace_a(new_component)
        did_dispatch.should eq 1
      end

      it "provides previous and new component OnComponentReplaced when replacing with same component" do
        entity = new_entity
        did_dispatch = 0
        component = A.new

        entity.on_component_replaced do |event|
          did_dispatch += 1
          event.entity.should be entity
          event.index.should eq Entitas::Component::Index::A.value
          event.prev_component.should be component
          event.new_component.should be component
        end

        entity.add_component(component)
        entity.replace_a(component)
        did_dispatch.should eq 1
      end

      it "doesn't dispatch anything when replacing a non existing component with null" do
        entity = new_entity

        entity.on_component_added { true.should eq false }
        entity.on_component_replaced { true.should eq false }
        entity.on_component_removed { true.should eq false }

        entity.replace_component(Entitas::Component::Index::A, nil)
      end

      it "dispatches OnComponentAdded when attempting to replace a component which hasn't been added" do
        entity = new_entity
        did_dispatch = 0
        new_component = A.new

        entity.on_component_added do |event|
          did_dispatch += 1
          event.entity.should be entity
          event.index.should eq Entitas::Component::Index::A.value
          event.component.should be new_component
        end

        entity.on_component_replaced { true.should eq false }
        entity.on_component_removed { true.should eq false }

        entity.replace_a(new_component)
        did_dispatch.should eq 1
      end

      it "dispatches OnComponentRemoved when replacing a component with null" do
        entity = new_entity_with_a
        did_dispatch = 0
        component = entity.a

        entity.on_component_added { true.should eq false }
        entity.on_component_replaced { true.should eq false }
        entity.on_component_removed do |event|
          did_dispatch += 1
          event.entity.should be entity
          event.index.should eq Entitas::Component::Index::A.value
          event.component.should be component
        end

        entity.replace_component(Entitas::Component::Index::A, nil)
        did_dispatch.should eq 1
      end

      it "dispatches OnComponentRemoved when removing all components" do
        entity = new_entity_with_ab
        did_dispatch = 0

        entity.on_component_removed { did_dispatch += 1 }

        entity.remove_all_components!
        did_dispatch.should eq 2
      end

      it "dispatches OnDestroy when calling Destroy" do
        entity = new_entity_with_a
        did_dispatch = 0

        entity.on_destroy_entity { did_dispatch += 1 }

        entity.destroy
      end
    end

    describe "reference counting" do
      owner = new_entity

      it "retains entity" do
        entity = new_entity
        entity.retain_count.should eq 0
        entity.retain(owner)
        entity.retain_count.should eq 1
        entity.aerc.should be_a(Entitas::SafeAERC)
        entity.aerc.as(Entitas::SafeAERC).includes?(owner).should be_true
      end

      it "releases entity" do
        entity = new_entity
        entity.retain(owner)
        entity.release(owner)

        entity.aerc.as(Entitas::SafeAERC).includes?(owner).should be_false
      end

      it "throws when releasing more than it has been retained" do
        entity = new_entity
        entity.retain(owner)
        entity.release(owner)

        expect_raises Entitas::Entity::Error::IsNotRetainedByOwner do
          entity.release(owner)
        end
      end

      it "throws when retaining twice with same owner" do
        entity = new_entity
        entity.retain(owner)
        expect_raises Entitas::Entity::Error::IsAlreadyRetainedByOwner do
          entity.retain(owner)
        end
      end

      it "throws when releasing with unknown owner" do
        entity = new_entity
        entity.retain(owner)
        unknown_owner = "You dont know me!"
        expect_raises Entitas::Entity::Error::IsNotRetainedByOwner do
          entity.release(unknown_owner)
        end
      end

      it "throws when releasing with owner which doesn't retain entity anymore" do
        owner2 = "second owner"
        entity = new_entity
        entity.retain(owner)
        entity.retain(owner2)
        entity.release(owner2)

        expect_raises Entitas::Entity::Error::IsNotRetainedByOwner do
          entity.release(owner2)
        end
      end

      describe "events" do
        it "doesn't dispatch OnEntityReleased when retaining" do
          entity = new_entity
          entity.on_entity_released { true.should eq false }
          entity.retain(owner)
        end

        it "dispatches OnEntityReleased when retain and release" do
          did_dispatch = 0
          entity = new_entity
          entity.on_entity_released do |event|
            did_dispatch += 1
            event.entity.should be entity
          end

          entity.retain(owner)
          entity.release(owner)

          did_dispatch.should eq 1
        end
      end
    end

    describe "internal caching" do
      describe "components" do
        it "caches components" do
          entity = new_entity_with_a
          cache = entity.get_components
          entity.get_components.should be cache
        end

        it "updates cache when a new component was added" do
          entity = new_entity_with_a
          cache = entity.get_components
          cache.should_not be_empty
          entity.add_b
          entity.get_components.should_not be cache
          entity.get_components.should_not eq cache
        end

        it "updates cache when a component was removed" do
          entity = new_entity_with_a
          cache = entity.get_components
          entity.del_a
          entity.get_components.should_not be cache
          entity.get_components.should_not eq cache
        end

        it "updates cache when a component was replaced" do
          entity = new_entity_with_a
          cache = entity.get_components
          entity.replace_component_a(A.new)
          entity.get_components.should_not be cache
          entity.get_components.should_not eq cache
        end

        it "doesn't update cache when a component was replaced with same component" do
          entity = new_entity_with_a
          cache = entity.get_components
          entity.replace_component(entity.a)
          entity.get_components.should be cache
        end

        it "updates cache when all components were removed" do
          entity = new_entity_with_a
          cache = entity.get_components
          entity.remove_all_components!
          entity.get_components.should_not be cache
          entity.get_components.should_not eq cache
        end
      end

      describe "component indices" do
        it "caches component indices" do
          entity = new_entity_with_a
          cache = entity.get_component_indices
          entity.get_component_indices.should be cache
        end

        it "updates cache when a new component was added" do
          entity = new_entity_with_a
          cache = entity.get_component_indices
          entity.add_b
          entity.get_component_indices.should_not be cache
          entity.get_component_indices.should_not eq cache
        end

        it "updates cache when a component was removed" do
          entity = new_entity_with_a
          cache = entity.get_component_indices
          entity.del_a
          entity.get_component_indices.should_not be cache
          entity.get_component_indices.should_not eq cache
        end

        it "doesn't update cache when a component was replaced" do
          entity = new_entity_with_a
          cache = entity.get_component_indices
          entity.replace_component_a(A.new)
          entity.get_component_indices.should be cache
          entity.get_component_indices.should eq cache
        end

        it "updates cache when adding a new component with replace_component" do
          entity = new_entity_with_a
          cache = entity.get_component_indices
          entity.replace_component_c(C.new)
          entity.get_component_indices.should_not be cache
          entity.get_component_indices.should_not eq cache
        end

        it "updates cache when all components were removed" do
          entity = new_entity_with_a
          cache = entity.get_component_indices
          entity.remove_all_components!
          entity.get_component_indices.should_not be cache
          entity.get_component_indices.should_not eq cache
        end
      end

      describe "to_string" do
        describe "when component was added" do
          it "caches entity description" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.to_s.should_not be cache
            entity.to_s.should eq cache
          end

          it "updates cache when a new component was added" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.add_b
            entity.to_s.should_not be cache
            entity.to_s.should_not eq cache
          end

          it "updates cache when a component was removed" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.del_a
            entity.to_s.should_not be cache
            entity.to_s.should_not eq cache
          end

          it "doesn't update cache when a component was replaced" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.replace_component_a(A.new)
            entity.to_s.should_not be cache
            entity.to_s.should eq cache
          end

          it "updates cache when all components were removed" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.replace_component(Entitas::Component::Index::A, nil)
            entity.to_s.should_not be cache
            entity.to_s.should_not eq cache
          end

          it "doesn't update cache when entity gets retained" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.retain(cache)
            entity.to_s.should eq cache
          end

          it "released entity doesn't have updated cache" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.retain(cache)
            entity.release(cache)
            entity.to_s.should eq cache
          end

          it "updates cache when remove_all_components is called, even if entity has no components" do
            entity = new_entity_with_a
            cache = entity.to_s
            entity.remove_all_components!
            entity.to_s.should_not be cache
            entity.to_s.should_not eq cache
          end
        end
      end
    end
  end
end
