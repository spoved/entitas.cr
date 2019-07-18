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
      new_context.entities.should be_empty
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
    end
  end
end
