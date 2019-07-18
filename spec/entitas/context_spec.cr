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
      ctx.info.name.should eq "Unnamed Context"
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
        ctx, e = context_with_entity
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
    end
  end
end
