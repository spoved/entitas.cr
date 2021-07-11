require "./systems/*"

module Entitas
  # Systems provide a convenient way to group systems.
  # You can add `InitializeSystem`, `ExecuteSystem`, `CleanupSystem`,
  # `TearDownSystem`, `ReactiveSystem` and other nested Systems instances.
  # All systems will be initialized and executed based on the order
  # you added them.
  class Systems
    Log = ::Log.for(self)

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
      {% if flag?(:entitas_enable_logging) %}Log.debug { "adding sub system : #{sys}" }{% end %}

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
      {% if flag?(:entitas_enable_logging) %}Log.trace { "running init on sub systems" }{% end %}
      self.initialize_systems.each &.init
    end

    # Calls `#execute` on all `ExecuteSystem` and other
    # nested `Systems` instances in the order you added them.
    def execute : Nil
      {% if flag?(:entitas_enable_logging) %}Log.trace { "running execute on sub systems" }{% end %}
      self.execute_systems.each &.execute
    end

    # Calls `#cleanup` on all `CleanupSystem` and other
    # nested `Systems` instances in the order you added them.
    def cleanup : Nil
      {% if flag?(:entitas_enable_logging) %}Log.trace { "running cleanup on sub systems" }{% end %}
      self.cleanup_systems.each &.cleanup
    end

    # Calls `#tear_down` on all `TearDownSystem` and other
    # nested `Systems` instances in the order you added them.
    def tear_down : Nil
      {% if flag?(:entitas_enable_logging) %}Log.trace { "running tear_down on sub systems" }{% end %}
      self.tear_down_systems.each &.tear_down
    end

    # Activates all `ReactiveSystems` in the systems list.
    def activate_reactive_systems : Nil
      {% if flag?(:entitas_enable_logging) %}Log.info { "activating sub reactive systems" }{% end %}
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
      {% if flag?(:entitas_enable_logging) %}Log.info { "deactivating sub reactive systems" }{% end %}

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
      {% if flag?(:entitas_enable_logging) %}Log.info { "clearing sub reactive systems" }{% end %}
      self.execute_systems.each do |sys|
        if sys.is_a?(Systems)
          sys.clear_reactive_systems
        else
          sys.clear if sys.is_a?(Entitas::Systems::ReactiveSystem)
        end
      end
    end

    # Recusivly searches for sub systems with the type provided and returns the first match
    def find_system(klass : Class) : Entitas::System?
      case self
      when klass
        self
      else
        sys = _find_system(cleanup_systems, klass)
        sys = _find_system(execute_systems, klass) if sys.nil?
        sys = _find_system(initialize_systems, klass) if sys.nil?
        sys = _find_system(tear_down_systems, klass) if sys.nil?
        sys
      end
    end

    # :no_doc:
    private def _find_system(_systems, klass)
      _systems.each do |sys|
        s = case sys
            when klass
              sys
            when Entitas::Systems, Entitas::Feature
              sys.find_system(klass)
            else
              nil
            end
        return s unless s.nil?
      end
      nil
    end

    # Recusivly searches for sub systems with the type provided and returns all matches
    def find_systems(klass : Class) : Array(Entitas::System)
      _systems = Array(Entitas::System).new
      _systems << self if self.class.==(klass)
      _systems.concat(_find_systems(cleanup_systems, klass))
      _systems.concat(_find_systems(execute_systems, klass))
      _systems.concat(_find_systems(initialize_systems, klass))
      _systems.concat(_find_systems(tear_down_systems, klass))
      _systems.uniq!
      _systems
    end

    # :no_doc:
    private def _find_systems(sub_systems, klass)
      _systems = Array(Entitas::System).new
      sub_systems.each do |sys|
        case sys
        when klass
          _systems << sys
        when Entitas::Systems, Entitas::Feature
          _systems.concat sys.find_systems(klass)
        else
        end
      end
      _systems
    end
  end
end
