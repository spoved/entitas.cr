require "./systems/*"

module Entitas
  # Systems provide a convenient way to group systems.
  # You can add `InitializeSystem`, `ExecuteSystem`, `CleanupSystem`,
  # `TearDownSystem`, `ReactiveSystem` and other nested Systems instances.
  # All systems will be initialized and executed based on the order
  # you added them.
  class Systems
    {% if flag?(:entitas_enable_logging) %}spoved_logger{% end %}

    include Entitas::Systems::CleanupSystem
    include Entitas::Systems::ExecuteSystem
    include Entitas::Systems::InitializeSystem
    include Entitas::Systems::TearDownSystem

    private getter cleanup_systems : Array(Entitas::Systems::CleanupSystem) = Array(Entitas::Systems::CleanupSystem).new
    private getter execute_systems : Array(Entitas::Systems::ExecuteSystem) = Array(Entitas::Systems::ExecuteSystem).new
    private getter initialize_systems : Array(Entitas::Systems::InitializeSystem) = Array(Entitas::Systems::InitializeSystem).new
    private getter tear_down_systems : Array(Entitas::Systems::TearDownSystem) = Array(Entitas::Systems::TearDownSystem).new

    # Adds the system instance to the systems list.
    def add(sys : Entitas::System) : Systems
      {% if flag?(:entitas_enable_logging) %}logger.debug("adding sub system : #{sys}", self.to_s){% end %}

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

      self
    end

    # Adds the system instance to the systems list.
    def <<(sys : Entitas::System)
      self.add(sys)
    end

    # Calls `#init` on all `InitializeSystem` and other
    # nested `Systems` instances in the order you added them.
    def init : Nil
      {% if flag?(:entitas_enable_logging) %}logger.info("running init on sub systems", self.to_s){% end %}
      self.initialize_systems.each &.init
    end

    # Calls `#execute` on all `ExecuteSystem` and other
    # nested `Systems` instances in the order you added them.
    def execute : Nil
      {% if flag?(:entitas_enable_logging) %}logger.info("running execute on sub systems", self.to_s){% end %}
      self.execute_systems.each &.execute
    end

    # Calls `#cleanup` on all `CleanupSystem` and other
    # nested `Systems` instances in the order you added them.
    def cleanup : Nil
      {% if flag?(:entitas_enable_logging) %}logger.info("running cleanup on sub systems", self.to_s){% end %}
      self.cleanup_systems.each &.cleanup
    end

    # Calls `#tear_down` on all `TearDownSystem` and other
    # nested `Systems` instances in the order you added them.
    def tear_down : Nil
      {% if flag?(:entitas_enable_logging) %}logger.info("running tear_down on sub systems", self.to_s){% end %}
      self.tear_down_systems.each &.tear_down
    end

    # Activates all `ReactiveSystems` in the systems list.
    def activate_reactive_systems : Nil
      {% if flag?(:entitas_enable_logging) %}logger.info("activating sub reactive systems", self.to_s){% end %}
      self.execute_systems.each do |sys|
        if sys.is_a?(Systems)
          sys.activate_reactive_systems
        else
          sys.activate if sys.is_a?(Entitas::Systems::ReactiveSystem)
        end
      end
    end

    # Deactivates all ReactiveSystems in the systems list.
    # This will also clear all ReactiveSystems.
    # This is useful when you want to soft-restart your application and
    # want to reuse your existing system instances.
    def deactivate_reactive_systems : Nil
      {% if flag?(:entitas_enable_logging) %}logger.info("deactivating sub reactive systems", self.to_s){% end %}

      self.execute_systems.each do |sys|
        if sys.is_a?(Systems)
          sys.deactivate_reactive_systems
        else
          sys.deactivate if sys.is_a?(Entitas::Systems::ReactiveSystem)
        end
      end
    end

    # Clears all `ReactiveSystems` in the systems list.
    def clear_reactive_systems
      {% if flag?(:entitas_enable_logging) %}logger.info("clearing sub reactive systems", self.to_s){% end %}
      self.execute_systems.each do |sys|
        if sys.is_a?(Systems)
          sys.clear_reactive_systems
        else
          sys.clear if sys.is_a?(Entitas::Systems::ReactiveSystem)
        end
      end
    end
  end
end
