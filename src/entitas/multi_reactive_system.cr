require "./systems"

module Entitas
  # A `Entitas::ReactiveSystem` calls Execute(entities) if there were changes based on
  # the specified `Entitas::Collector` and will only pass in changed entities.
  # A common use-case is to react to changes, e.g. a change of the position
  # of an entity to update the gameObject.transform.position
  # of the related gameObject.
  abstract class MultiReactiveSystem
    Log = ::Log.for(self)

    include Entitas::Systems::ReactiveSystem

    private getter collectors : Array(ICollector)
    private property collected_buffer : Array(IEntity) = Array(IEntity).new
    private property buffer : Array(IEntity) = Array(IEntity).new
    private property to_string_cache : String? = nil
    protected property _filter : Proc(IEntity, Bool) = ->(entity : IEntity) { true }

    def initialize(@collectors : Array(ICollector)); end

    def initialize(collectors : Array(ICollector), filter : Proc(IEntity, Bool))
      @collectors = collectors
      @_filter = filter
    end

    def initialize(context : Entitas::Context, filter : Proc(IEntity, Bool))
      @collectors = get_trigger(context)
      @_filter = filter
    end

    def initialize(contexts : ::Contexts)
      @collectors = get_trigger(contexts)
    end

    # Specify the collector that will trigger the ReactiveSystem.
    abstract def get_trigger(contexts : ::Contexts) : Array(ICollector)

    # This will exclude all entities which don't pass the filter.
    def filter(entity)
      self._filter.call(entity)
    end

    abstract def execute(entities : Array(IEntity))

    # Activates the `ReactiveSystem` and starts observing changes
    # based on the specified `Collector`.
    # `ReactiveSystem` are activated by default.
    def activate
      self.collectors.each &.activate
    end

    # Deactivates the `ReactiveSystem`.
    # No changes will be tracked while deactivated.
    # This will also clear the `ReactiveSystem`.
    # `ReactiveSystem` are activated by default.
    def deactivate
      self.collectors.each &.deactivate
    end

    # Alias. See `#clear`
    def clear_collected_entities
      self.clear
    end

    # Clears all accumulated changes.
    def clear
      {% if flag?(:entitas_enable_logging) %}Log.info { "clearing system" }{% end %}

      self.collectors.each &.clear
    end

    def execute
      self.collectors.each do |collector|
        unless collector.empty?
          collector.entities.each do |e|
            self.collected_buffer << e.as(Entitas::IEntity)
          end
          collector.clear
        end
      end

      collected_buffer.each do |e|
        if self.filter(e)
          e.retain(self)
          self.buffer << e unless buffer.includes?(e)
        end
      end

      unless self.buffer.empty?
        begin
          self.execute(self.buffer)
        ensure
          self.buffer.each { |e| e.release(self) }

          self.collected_buffer.clear
          self.buffer.clear
        end
      end
    end

    def to_s(io)
      self.to_string_cache = "MultiReactiveSystem(#{self.class})" if to_string_cache.nil?
      io << to_string_cache
    end
  end
end
