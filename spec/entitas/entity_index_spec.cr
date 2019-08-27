require "../spec_helper"

private def name
  "Max"
end

private def new_index
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(NameAge))
  index = Entitas::EntityIndex(TestEntity, String).new("TestIndex", group, ->(entity : TestEntity, component : Entitas::Component?) {
    (component.nil? ? entity.get_component_name_age.name : component.as(NameAge).name).as(String)
  })
  name_age = NameAge.new(name: name)
  e1 = ctx.create_entity
  e1.add_component(name_age)
  e2 = ctx.create_entity
  e2.add_component(name_age)
  {[e1, e2], index, group, ctx}
end

private def new_mk_index
  ctx = new_context
  group = ctx.get_group(Entitas::Matcher.all_of(NameAge))

  e1 = ctx.create_entity
  e2 = ctx.create_entity

  index = Entitas::EntityIndex(TestEntity, String).new(
    "TestIndex",
    group,
    ->(entity : TestEntity, component : Entitas::Component?) {
      (e1 == entity ? (
        ["1", "2"]
      ) : (
        ["2", "3"]
      )).as(Array(String))
    }
  )
  name_age = NameAge.new(name: name)

  e1.add_component(name_age)
  e2.add_component(name_age)

  {[e1, e2], index, group, ctx}
end

describe Entitas::EntityIndex do
  describe "single key" do
    describe "when entity for key doesn't exist" do
      it "has no entities" do
        ctx = new_context
        group = ctx.get_group(Entitas::Matcher.all_of(NameAge))
        index = Entitas::EntityIndex(TestEntity, String).new("TestIndex", group, ->(entity : TestEntity, component : Entitas::Component?) {
          (component.nil? ? entity.get_component_name_age.name : component.as(NameAge).name).as(String)
        })
        index.get_entities("unknown_key").should be_empty
      end
    end

    describe "gets entities for key" do
      it "gets entity for key" do
        entities, index = new_index
        index.get_entities(name).size.should eq 2
        index.get_entities(name).should contain(entities[0])
        index.get_entities(name).should contain(entities[1])
      end

      it "retains entity" do
        entities, _ = new_index
        entities[0].retain_count.should eq 3 # Context, Group, EntityIndex
        entities[1].retain_count.should eq 3 # Context, Group, EntityIndex
      end

      it "has existing entities" do
        entities, _, group = new_index
        index = Entitas::EntityIndex(TestEntity, String).new("TestIndex", group, ->(entity : TestEntity, component : Entitas::Component?) {
          (component.nil? ? entity.get_component_name_age.name : component.as(NameAge).name).as(String)
        })
        index.get_entities(name).size.should eq 2
      end

      it "releases and removes entity from index when component gets removed" do
        entities, index = new_index
        entity = entities[0]
        entity.del_name_age
        index.get_entities(name).size.should eq 1
        entity.retain_count.should eq 1
      end

      it "can to_s" do
        _, index = new_index
        index.to_s.should eq "EntityIndex(TestIndex)"
      end
    end

    describe "when deactivated" do
      it "clears index and releases entities" do
        entities, index = new_index
        index.deactivate

        index.get_entities(name).should be_empty
        entities[0].retain_count.should eq 2 # Context, Group
        entities[1].retain_count.should eq 2 # Context, Group
      end

      it "doesn't add entities anymore" do
        _, index, group, ctx = new_index
        index.deactivate

        c = NameAge.new(name: name)
        entity = ctx.create_entity
        entity.add_component(c)

        index.get_entities(name).should be_empty
      end

      describe "when activated" do
        it "has existing entity" do
          entities, index = new_index
          index.deactivate
          index.activate

          index.get_entities(name).size.should eq 2
          index.get_entities(name).should contain(entities[0])
          index.get_entities(name).should contain(entities[1])
        end

        it "adds new entities" do
          entities, index, _, ctx = new_index
          index.deactivate
          index.activate

          c = NameAge.new(name: name)
          entity = ctx.create_entity
          entity.add_component(c)

          index.get_entities(name).size.should eq 3
          index.get_entities(name).should contain(entities[0])
          index.get_entities(name).should contain(entities[1])
          index.get_entities(name).should contain(entity)
        end
      end
    end
  end

  describe "multiple keys" do
    describe "when entity for key exists" do
      it "retains entity" do
        entities, index = new_mk_index
        entities[0].retain_count.should eq 3 # Context, Group, EntityIndex
        entities[0].aerc.includes?(index).should be_true
        entities[1].retain_count.should eq 3 # Context, Group, EntityIndex
        entities[1].aerc.includes?(index).should be_true
      end

      it "has entity" do
        _, index = new_mk_index
        index.get_entities("1").size.should eq 1
        index.get_entities("2").size.should eq 2
        index.get_entities("3").size.should eq 1
      end

      it "gets entity for key" do
        entities, index = new_mk_index
        index.get_entities("1").first.should be entities[0]
        index.get_entities("2").should contain(entities[0])
        index.get_entities("2").should contain(entities[1])
        index.get_entities("3").first.should be entities[1]
      end

      it "releases and removes entity from index when component gets removed" do
        entities, index = new_mk_index
        entity = entities.first
        entity.del_name_age

        index.get_entities("1").size.should eq 0
        index.get_entities("2").size.should eq 1
        index.get_entities("3").size.should eq 1

        entities[0].retain_count.should eq 1 # Context
        entities[1].retain_count.should eq 3 # Context, Group, EntityIndex

        entities[0].aerc.includes?(index).should be_false
        entities[1].aerc.includes?(index).should be_true
      end

      it "has existing entity" do
        entities, index = new_mk_index
        index.deactivate
        index.activate
        index.get_entities("1").first.should be entities[0]
        index.get_entities("2").should contain(entities[0])
        index.get_entities("2").should contain(entities[1])
        index.get_entities("3").first.should be entities[1]
      end
    end
  end

  describe "when index multiple components" do
    it "gets last component that triggered adding entity to group" do
      ctx = new_context
      rec_comp : Entitas::Component? = nil

      group = ctx.get_group(Entitas::Matcher.all_of(NameAge, B))

      index = Entitas::EntityIndex(TestEntity, String).new(
        "TestIndex",
        group,
        ->(entity : TestEntity, component : Entitas::Component?) {
          rec_comp = component
          # (component.nil? ? entity.get_component_name_age.name : component.as(NameAge).name).as(String)
          component.to_s
        }
      )

      c1 = NameAge.new(name: "Max")
      # c2 = NameAge.new(name: "Jack")
      c2 = B.new

      entity = ctx.create_entity
      entity.add_component(c1)
      entity.add_component(c2)

      rec_comp.should be c2
    end

    it "works with none_of" do
      ctx = new_context
      rec_comps = Array(Entitas::Component).new

      group = ctx.get_group(Entitas::Matcher.all_of(NameAge).none_of(B))

      index = Entitas::EntityIndex(TestEntity, String).new(
        "TestIndex",
        group,
        ->(entity : TestEntity, component : Entitas::Component?) {
          rec_comps << component unless component.nil?
          # (component.nil? ? entity.get_component_name_age.name : component.as(NameAge).name).as(String)
          component.to_s
        }
      )

      c1 = NameAge.new(name: "Max")
      # name_age2 = NameAge.new(name: "Jack")
      c2 = B.new

      entity = ctx.create_entity
      entity.add_component(c1)
      entity.add_component(c2)

      rec_comps.size.should eq 2
      rec_comps[0].should be c1
      rec_comps[1].should be c2
    end
  end
end
