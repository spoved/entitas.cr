require "../spec_helper"

describe Entitas::Entity do
  describe "initial state" do
    it "has default context info" do
      entity = new_entity
      entity.context_info.name.should eq "No Context"
      entity.context_info.component_names.size.should eq Entitas::Component::TOTAL_COMPONENTS
    end

    describe "destroyed" do
      it "raises IsNotEnabledException when adding a component" do
        entity = new_entity
        entity.destroy!
        expect_raises Entitas::Entity::IsNotEnabledException do
          entity.add_a
        end
      end

      it "wont raise IsNotEnabledException with context index" do
        entity = new_entity
        entity.add_a
      end
    end

    it "reactivates after being destroyed" do
      entity = new_entity
      entity.enabled?.should be_truthy

      entity.destroy!
      entity.enabled?.should be_falsey

      entity.reactivate(42)
      entity.enabled?.should be_truthy
    end

    it "throws when attempting to get component at index which hasn't been added" do
      entity = new_entity
      expect_raises Entitas::Entity::DoesNotHaveComponentException do
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
      expect_raises Entitas::Entity::DoesNotHaveComponentException do
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
      expect_raises Entitas::Entity::AlreadyHasComponentException do
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
    end
  end
end
