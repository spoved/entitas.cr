require "../../stack"
require "../component"
require "../entity/index"
require "../entity/aerc"
require "./info"
require "graphite"
require "../events/context"

module Entitas
  # A context manages the lifecycle of entities and groups.
  #  You can create and destroy entities and get groups of entities.
  #  The prefered way to create a context is to use the generated methods
  #  from the code generator, e.g. var context = new GameContext();
  abstract class Context
    @_entities : Array(Entitas::Entity) = Array(Entitas::Entity).new
    @_reusable_entities : Stack(Entitas::Entity) = Stack(Entitas::Entity).new
    @_retained_entities : Array(Entitas::Entity) = Array(Entitas::Entity).new
    @_total_components : Int32 = 0
    @_component_pools : Stack(Entitas::Component) = Stack(Entitas::Component).new
    @_context_info : Context::Info
    @_aerc_factory : Proc(Entitas::Entity, Entitas::SafeAERC(Entitas::Entity))

    # _groups
    # _groupsForIndex
    # _groupChangedListPool
    @_entity_indices : Hash(String, Entitas::Entity::Index) = Hash(String, Entitas::Entity::Index).new
    @_creation_index : Int32 = 0
    @_entities_cache : Array(Entitas::Entity) = Array(Entitas::Entity).new

    @_cached_entity_changed : Proc(Entitas::Entity, Int32, Entitas::Component, Nil)
    @_cached_component_replaced : Proc(Entitas::Entity, Int32, Entitas::Component, Entitas::Component, Nil)
    @_cached_entity_released : Proc(Entitas::Entity, Nil)
    @_cached_destroy_entity : Proc(Entitas::Entity, Nil)

    def initialize(total_components : Int32)
      initialize(total_components, 0, nil, nil)
    end

    def initialize(total_components : Int32, start_creation_index : Int32,
                   context_info : Entitas::Context::Info | Nil,
                   aerc_factory : Proc(Entitas::Entity, Entitas::AERC) | Nil)
      @_total_components = total_components
      @_creation_index = start_creation_index
      @_context_info = context_info || create_default_context_info
      @_aerc_factory = aerc_factory.nil? ? ->(entity : Entitas::Entity) { SafeAERC(Entitas::Entity).new(entity) } : aerc_factory

      # Cache delegates to avoid gc allocations
      @_cached_entity_changed = ->update_groups_component_added_or_removed(Entitas::Entity, Int32, Entitas::Component)
      @_cached_component_replaced = ->update_groups_component_replaced(Entitas::Entity, Int32, Entitas::Component, Entitas::Component)
      @_cached_entity_released = ->on_entity_released(Entitas::Entity)
      @_cached_destroy_entity = ->on_destroy_entity(Entitas::Entity)
    end

    def create_default_context_info : Entitas::Context::Info
      component_names = Array(String).new
      prefix = "Index "
      total_components.times do |i|
        component_names << prefix + i.to_s
      end

      Entitas::Context::Info.new("Unnamed Context", component_names, Array(Component.class).new)
    end

    def total_components : Int32
      @_total_components
    end

    def component_pools : Stack(Entitas::Component)
      @_component_pools
    end

    def context_info : Context::Info
      @_context_info
    end

    # Returns the total number of `Entitas::Entity` in this `Context`
    def size
      @_entities.size
    end

    def reusable_entities_size
      @_reusable_entities.size
    end

    def retained_entities_size
      @_retained_entities.size
    end

    # Creates a new entity or gets a reusable entity from the internal ObjectPool for entities.
    def create_entity : Entitas::Entity
      if reusable_entities_size > 0
        entity = @_reusable_entities.pop
        @_creation_index += 1
        entity.reactivate(@_creation_index)
      else
        entity = Entitas::Entity.new
        @_creation_index += 1
        entity.init(@_creation_index, @_total_components, @_component_pools, @_context_info, @_aerc_factory.call(entity))
      end
    end

    # Destroys the entity, removes all its components and pushs it back
    #   to the internal ObjectPool for entities.
    def destroy_entity(entity : Entitas::Entity)
    end

    # Destroys all entities in the context.
    def destroy_all_entities
      get_entities.each do |entity|
        destroy_entity(entity)
      end
      @_entities.clear
    end

    # Determines whether the context has the specified entity.
    def has_entity?(entity : Entitas::Entity) : Bool
      @_entities.includes? entity
    end

    # Returns all entities which are currently in the context
    def get_entities : Array(Entitas::Entity)
      @_entities
    end

    # Adds the IEntityIndex for the specified name.
    # There can only be one IEntityIndex per name.
    def add_entity_index(entity_index : Entitas::Entity::Index)
      if (@_entity_indicies.key?(entity_index.name))
        raise ContextEntityIndexDoesAlreadyExistException.new(self, entity_index.name)
      end
      @_entity_indicies[entity_index.name] = entity_index
    end

    # Gets the IEntityIndex for the specified name.
    def get_entity_index(name : String) : Entitas::Entity::Index
      unless (@_entity_indicies.key?(entity_index.name))
        raise ContextEntityIndexDoesNotExistException.new(self, name)
      end
      @_entity_indicies[name]
    end

    # Resets the creationIndex back to 0.
    def reset_creation_index
      @_creation_index = 0
    end

    # Clears the componentPool at the specified index.
    def clear_component_pool(index : Int32)
      @_component_pools[index].clear if @_component_pools[index]?
    end

    # Clears all component pools.
    def clear_component_pools
      @_component_pools.each do |pool|
        pool.clear
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

    def update_groups_component_added_or_removed(entity : Entitas::Entity, index : Int32, component : Entitas::Component) : Nil
    end

    def update_groups_component_replaced(entity : Entitas::Entity, index : Int32,
                                         previous_component : Entitas::Component, new_component : Entitas::Component) : Nil
    end

    def on_entity_released(entity : Entitas::Entity) : Nil
    end

    def on_destroy_entity(entity : Entitas::Entity) : Nil
    end
  end
end
