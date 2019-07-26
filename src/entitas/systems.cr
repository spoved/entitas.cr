require "../entitas"
require "./systems/*"

module Entitas
  # Systems provide a convenient way to group systems.
  # You can add `InitializeSystem`, `ExecuteSystem`, `CleanupSystem`,
  # `TearDownSystem`, `ReactiveSystem` and other nested Systems instances.
  # All systems will be initialized and executed based on the order
  # you added them.
  abstract class Systems
    include Entitas::Systems::CleanupSystem
    include Entitas::Systems::ExecuteSystem
    include Entitas::Systems::InitializeSystem
    include Entitas::Systems::TearDownSystem
    include Entitas::Systems::ReactiveSystem

    private getter cleanup_systems : Array(Entitas::Systems::CleanupSystem) = Array(Entitas::Systems::CleanupSystem).new
    private getter execute_systems : Array(Entitas::Systems::ExecuteSystem) = Array(Entitas::Systems::ExecuteSystem).new
    private getter initialize_systems : Array(Entitas::Systems::InitializeSystem) = Array(Entitas::Systems::InitializeSystem).new
    private getter tear_down_systems : Array(Entitas::Systems::TearDownSystem) = Array(Entitas::Systems::TearDownSystem).new
    private getter reactive_systems : Array(Entitas::Systems::ReactiveSystem) = Array(Entitas::Systems::ReactiveSystem).new

    # Adds the system instance to the systems list.
    def add(sys : Entitas::System) : Systems
      if sys.is_a?(Entitas::Systems::CleanupSystem)
        cleanup_systems << sys unless cleanup_systems.includes?(sys)
      end

      if sys.is_a?(Entitas::Systems::ExecuteSystem)
        execute_systems << sys unless execute_systems.includes?(sys)
      end

      if sys.is_a?(Entitas::Systems::InitializeSystem)
        initialize_systems << sys unless initialize_systems.includes?(sys)
      end

      if sys.is_a?(Entitas::Systems::TearDownSystem)
        tear_down_systems << sys unless tear_down_systems.includes?(sys)
      end

      if sys.is_a?(Entitas::Systems::ReactiveSystem)
        reactive_systems << sys unless reactive_systems.includes?(sys)
      end

      self
    end

    # Adds the system instance to the systems list.
    def <<(sys : Entitas::System)
      self.add(sys)
    end

    # Calls `#init` on all `InitializeSystem` and other
    # nested `Systems` instances in the order you added them.
    def init
      self.initialize_systems.each &.init
    end

    # Calls `#execute` on all `ExecuteSystem` and other
    # nested `Systems` instances in the order you added them.
    def execute
      self.execute_systems.each &.execute
    end

    # Calls `#cleanup` on all `CleanupSystem` and other
    # nested `Systems` instances in the order you added them.
    def cleanup
      self.execute_systems.each &.cleanup
    end

    # Calls `#tear_down` on all `TearDownSystem` and other
    # nested `Systems` instances in the order you added them.
    def tear_down
      self.cleanup_systems.each &.tear_down
    end

    # Activates all `ReactiveSystems` in the systems list.
    def activate_reactive_systems
      self.reactive_systems.each do |sys|
        if sys.is_a?(Systems)
          sys.activate_reactive_systems
        else
          sys.activate
        end
      end
    end

    # Deactivates all ReactiveSystems in the systems list.
    # This will also clear all ReactiveSystems.
    # This is useful when you want to soft-restart your application and
    # want to reuse your existing system instances.
    def deactivate_reactive_systems
      self.reactive_systems.each do |sys|
        if sys.is_a?(Systems)
          sys.deactivate_reactive_systems
        else
          sys.deactivate
        end
      end
    end

    # Clears all `ReactiveSystems` in the systems list.
    def clear_reactive_systems
      self.reactive_systems.each do |sys|
        if sys.is_a?(Systems)
          sys.clear_reactive_systems
        else
          sys.clear
        end
      end
    end
  end
end
