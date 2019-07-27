require "../spec_helper"

def new_reactive_system
  ctx = MyTestContext.new
  sys = ReactiveSystemSpy.new(ctx.create_collector(Entitas::Matcher.all_of(A)))
  e = ctx.create_entity.add_a
  {sys, ctx, e}
end

describe Entitas::Systems do
  new_reactive_system

  describe "fixtures" do
    it "initializes InitializeSystemSpy" do
      sys = InitializeSystemSpy.new
      sys.did_initialize.should eq 0
      sys.init
      sys.did_initialize.should eq 1
    end

    it "initializes ExecuteSystemSpy" do
      sys = ExecuteSystemSpy.new
      sys.did_execute.should eq 0
      sys.execute
      sys.did_execute.should eq 1
    end

    it "initializes CleanupSystemSpy" do
      sys = CleanupSystemSpy.new
      sys.did_cleanup.should eq 0
      sys.cleanup
      sys.did_cleanup.should eq 1
    end

    it "initializes TearDownSystemSpy" do
      sys = TearDownSystemSpy.new
      sys.did_tear_down.should eq 0
      sys.tear_down
      sys.did_tear_down.should eq 1
    end

    it "initializes, executes, cleans up and tears down system" do
      sys, _, _ = new_reactive_system

      sys.did_initialize.should eq 0
      sys.init
      sys.did_initialize.should eq 1

      sys.did_execute.should eq 0
      sys.execute
      sys.did_execute.should eq 1

      sys.did_cleanup.should eq 0
      sys.cleanup
      sys.did_cleanup.should eq 1

      sys.did_tear_down.should eq 0
      sys.tear_down
      sys.did_tear_down.should eq 1
    end

    it "executes ReactiveSystemSpy" do
      sys, _, _ = new_reactive_system
      sys.execute
      sys.entities.size.should eq 1
    end
  end

  describe "systems" do
    it "returns systems when adding system" do
      systems = Entitas::Systems.new
      systems.add(InitializeSystemSpy.new).should be systems
    end

    it "initializes InitializeSystem" do
      systems = Entitas::Systems.new
      sys = InitializeSystemSpy.new
      systems.add(sys).should be systems
      systems.init
      sys.did_initialize.should eq 1
    end

    it "initializes ExecuteSystem" do
      systems = Entitas::Systems.new
      sys = ExecuteSystemSpy.new
      systems.add(sys).should be systems
      systems.execute
      sys.did_execute.should eq 1
    end

    it "wraps ReactiveSystem in a ReactiveSystem" do
      ctx = MyTestContext.new
      sys = ReactiveSystemSpy.new(ctx.create_collector(Entitas::Matcher.all_of(A)))

      systems = Entitas::Systems.new
      systems.add sys
      ctx.create_entity.add_a
      systems.execute

      sys.did_execute.should eq 1
    end

    it "adds ReactiveSystem" do
      ctx = MyTestContext.new
      sys = ReactiveSystemSpy.new(ctx.create_collector(Entitas::Matcher.all_of(A)))

      systems = Entitas::Systems.new
      systems.add sys
      ctx.create_entity.add_a
      systems.execute

      sys.did_execute.should eq 1
    end

    it "cleans up CleanupSystem" do
      systems = Entitas::Systems.new
      sys = CleanupSystemSpy.new
      systems.add(sys).should be systems
      systems.cleanup
      sys.did_cleanup.should eq 1
    end

    it "initializes, executes, cleans up and tears down InitializeExecuteCleanupTearDownSystemSpy" do
      systems = Entitas::Systems.new
      sys, _, _ = new_reactive_system

      systems << sys

      sys.did_initialize.should eq 0
      systems.init
      sys.did_initialize.should eq 1

      sys.did_execute.should eq 0
      systems.execute
      sys.did_execute.should eq 1

      sys.did_cleanup.should eq 0
      systems.cleanup
      sys.did_cleanup.should eq 1

      sys.did_tear_down.should eq 0
      systems.tear_down
      sys.did_tear_down.should eq 1
    end

    it "initializes, executes, cleans up and tears down ReactiveSystem" do
      systems = Entitas::Systems.new
      sys, _ = new_reactive_system

      systems << sys

      sys.did_initialize.should eq 0
      systems.init
      sys.did_initialize.should eq 1

      sys.did_execute.should eq 0
      systems.execute
      systems.execute
      sys.did_execute.should eq 1

      sys.did_cleanup.should eq 0
      systems.cleanup
      sys.did_cleanup.should eq 1

      sys.did_tear_down.should eq 0
      systems.tear_down
      sys.did_tear_down.should eq 1
    end

    it "initializes, executes, cleans up and tears down systems recursively" do
      systems = Entitas::Systems.new
      sys, _ = new_reactive_system

      systems << sys

      parent_systems = Entitas::Systems.new
      parent_systems.add systems

      sys.did_initialize.should eq 0
      parent_systems.init
      sys.did_initialize.should eq 1

      sys.did_execute.should eq 0
      parent_systems.execute
      parent_systems.execute
      sys.did_execute.should eq 1

      sys.did_cleanup.should eq 0
      parent_systems.cleanup
      sys.did_cleanup.should eq 1

      sys.did_tear_down.should eq 0
      parent_systems.tear_down
      sys.did_tear_down.should eq 1
    end

    it "clears reactive systems" do
      systems = Entitas::Systems.new
      sys, _ = new_reactive_system

      systems << sys

      systems.init
      sys.did_initialize.should eq 1

      systems.clear_reactive_systems
      systems.execute
      sys.did_execute.should eq 0
    end

    it "deactivates reactive systems" do
      systems = Entitas::Systems.new
      sys, _ = new_reactive_system

      systems << sys

      systems.init
      sys.did_initialize.should eq 1

      systems.deactivate_reactive_systems
      systems.execute
      sys.did_execute.should eq 0
    end

    it "deactivates reactive systems recursively" do
      systems = Entitas::Systems.new
      sys, _ = new_reactive_system
      systems << sys

      parent_systems = Entitas::Systems.new
      parent_systems.add systems
      parent_systems.init
      sys.did_initialize.should eq 1

      parent_systems.deactivate_reactive_systems
      parent_systems.execute

      sys.did_execute.should eq 0
    end

    it "activates reactive systems" do
      systems = Entitas::Systems.new
      sys, ctx = new_reactive_system

      systems << sys

      systems.init
      sys.did_initialize.should eq 1

      systems.deactivate_reactive_systems
      systems.activate_reactive_systems

      ctx.create_entity.add_a
      systems.execute
      sys.did_execute.should eq 1
    end

    it "activates reactive systems recursively" do
      systems = Entitas::Systems.new
      sys, ctx = new_reactive_system

      systems << sys

      parent_systems = Entitas::Systems.new
      parent_systems.add systems

      parent_systems.init
      sys.did_initialize.should eq 1

      parent_systems.deactivate_reactive_systems
      parent_systems.activate_reactive_systems

      ctx.create_entity.add_a
      parent_systems.execute
      sys.did_execute.should eq 1
    end
  end
end
