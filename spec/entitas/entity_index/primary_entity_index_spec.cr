require "../../spec_helper"

private def name
  "Max"
end

private def new_index
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(NameAge))
  index = Entitas::PrimaryEntityIndex(TestEntity, String).new(
    name: "TestIndex",
    group: group,
    get_key: ->(entity : TestEntity, component : Entitas::Component?) {
      (component.nil? ? entity.as(TestEntity).get_component_name_age.name : component.as(NameAge).name).as(String)
    }
  )
  name_age = NameAge.new(name: name)
  entity = ctx.create_entity
  entity.add_component(name_age)
  {entity, index, group, ctx}
end

private def new_mk_index
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(NameAge))
  index = Entitas::PrimaryEntityIndex(TestEntity, String).new(
    "TestIndex",
    group,
    ->(entity : TestEntity, component : Entitas::Component?) {
      (component.nil? ? (
        ["#{entity.get_component_name_age.name}1", "#{entity.get_component_name_age.name}2"]
      ) : (
        ["#{component.as(NameAge).name}1", "#{component.as(NameAge).name}2"]
      )).as(Array(String))
    }
  )
  name_age = NameAge.new(name: name)
  entity = ctx.create_entity
  entity.add_component(name_age)
  {entity, index, group, ctx}
end

describe Entitas::PrimaryEntityIndex do
  describe "single key" do
    describe "when entity for key doesn't exist" do
      it "returns null when getting entity for unknown key" do
        _, index = new_index
        index.get_entity("unknown_key").should be_nil
      end
    end

    describe "when entity for key exists" do
      it "gets entity for key" do
        entity, index = new_index
        index.get_entity(name).should be entity
      end

      it "retains entity" do
        entity, _ = new_index
        entity.retain_count.should eq 3 # Context, Group, EntityIndex
      end

      it "has existing entity" do
        e, _, group = new_index
        index = Entitas::PrimaryEntityIndex(TestEntity, String).new(
          "TestIndex",
          group,
          ->(entity : TestEntity, component : Entitas::Component?) {
            (component.nil? ? entity.get_component_name_age.name : component.as(NameAge).name).as(String)
          }
        )
        index.get_entity(name).should be e
      end

      it "releases and removes entity from index when component gets removed" do
        entity, index = new_index
        entity.del_name_age
        index.get_entity(name).should be_nil
        entity.retain_count.should eq 1
      end

      it "throws when adding an entity for the same key" do
        expect_raises Entitas::EntityIndex::Error do
          _, _, _, ctx = new_index
          c = NameAge.new(name: name)
          entity = ctx.create_entity
          entity.add_component(c)
        end
      end

      it "can to_s" do
        _, index = new_index
        index.to_s.should eq "PrimaryEntityIndex(TestIndex)"
      end
    end

    describe "when deactivated" do
      it "clears index and releases entity" do
        entity, index = new_index
        index.deactivate

        index.get_entity(name).should be_nil
        entity.retain_count.should eq 2
      end

      it "doesn't add entities anymore" do
        _, index, group, ctx = new_index
        index.deactivate

        c = NameAge.new(name: name)
        entity = ctx.create_entity
        entity.add_component(c)

        index.get_entity(name).should be_nil
      end

      describe "when activated" do
        it "has existing entity" do
          entity, index = new_index
          index.deactivate
          index.activate

          index.get_entity(name).should be entity
        end

        it "adds new entities" do
          _, index, _, ctx = new_index
          index.deactivate
          index.activate

          c = NameAge.new(name: "Jack")
          entity = ctx.create_entity
          entity.add_component(c)

          index.get_entity("Jack").should be entity
        end
      end
    end
  end

  describe "multiple keys" do
    describe "when entity for key exists" do
      it "retains entity" do
        entity, index = new_mk_index
        entity.retain_count.should eq 3 # Context, Group, EntityIndex
        entity.aerc.includes?(index).should be_true
      end

      it "gets entity for key" do
        entity, index = new_mk_index
        index.get_entity("#{name}1").should be entity
        index.get_entity("#{name}2").should be entity
      end

      it "releases and removes entity from index when component gets removed" do
        entity, index = new_mk_index
        entity.del_name_age

        index.get_entity("#{name}1").should be_nil
        index.get_entity("#{name}2").should be_nil

        entity.retain_count.should eq 1

        entity.aerc.includes?(index).should be_false
      end

      it "has existing entity" do
        entity, index, _, _ = new_mk_index
        index.deactivate
        index.activate
        index.get_entity("#{name}1").should be entity
        index.get_entity("#{name}2").should be entity
      end
    end
  end
end
