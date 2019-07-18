require "./component"
require "./component/helper"
require "./entity"
require "./context/*"

module Entitas
  # A context manages the lifecycle of entities and groups.
  #  You can create and destroy entities and get groups of entities.
  #  The prefered way to create a context is to use the generated methods
  #  from the code generator, e.g. var context = new GameContext();
  abstract class Context
    include Entitas::Entity::Events
    include Entitas::Component::Helper

    property creation_index : Int32
    getter aerc_factory : AERCFactory
    getter entity_factory : EntityFactory
    @context_info : Context::Info

    getter entities = Array(Entity).new
    getter reusable_entities = Array(Entity).new
    getter retained_entities = Array(Entity).new

    def initialize(
      # @total_components : Int32 = ::Entitas::Component::TOTAL_COMPONENTS,
      @creation_index : Int32 = 0,
      context_info : Entitas::Context::Info? = nil,
      @aerc_factory : AERCFactory = AERCFactory.new { |entity| Entitas::SafeAERC.new(entity) },
      @entity_factory : EntityFactory = EntityFactory.new { Entitas::Entity.new }
    )
      @context_info = context_info || create_default_context_info
      # @component_pools = Array(ComponentPool).new(total_components)

      if @context_info.component_names.size != self.total_components
        raise InfoException.new(self, @context_info)
      end
    end

    # Resets the context (destroys all entities and resets creationIndex back to 0).
    def reset
      destroy_all_entities
      reset_creation_index

      # OnEntityCreated = null;
      # OnEntityWillBeDestroyed = null;
      # OnEntityDestroyed = null;
      # OnGroupCreated = null;
    end

    ############################
    # Context::Info functions
    ############################

    private def create_default_context_info : Entitas::Context::Info
      component_names = Array(String).new
      prefix = "Index "
      total_components.times do |i|
        component_names << prefix + i.to_s
      end

      Entitas::Context::Info.new("Unnamed Context", component_names, ::Entitas::Component::COMPONENT_MAP.keys)
    end

    # The contextInfo contains information about the context.
    # It's used to provide better error messages.
    def context_info : Context::Info
      @context_info
    end

    # See `context_info`
    def info : Context::Info
      self.context_info
    end

    ############################
    # Entity functions
    ############################

    # Returns the total number of `Entitas::Entity` in this `Context`
    def size
      self.entities.size
    end

    # Creates a new entity or gets a reusable entity from the internal ObjectPool for entities.
    def create_entity : Entitas::Entity
      if self.reusable_entities.size > 0
        entity = self.reusable_entities.pop
        entity.reactivate(self.creation_index)
        self.creation_index += 1
        entity
      else
        entity = self.entity_factory.call
        entity.init(self.creation_index, self.context_info, self.aerc_factory.call(entity))
        self.creation_index += 1
        entity
      end
    end

    ############################
    # ComponentPool functions
    ############################

    # Clears the `ComponentPool` at the specified index.
    def clear_component_pool(index : Int32)
      component_pools[index].clear
    end

    # Clears all `ComponentPool`s.
    def clear_component_pools
      component_pools.each do |pool|
        pool.clear
      end
    end

    ############################
    # Misc functions
    ############################

    def to_s
      info.name
    end
  end
end
