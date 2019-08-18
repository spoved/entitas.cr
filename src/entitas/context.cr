require "./*"
require "./context/macros"
require "./context/*"
require "spoved/logger"
require "./events"

module Entitas
  # A context manages the lifecycle of entities and groups.
  #  You can create and destroy entities and get groups of entities.
  #  The prefered way to create a context is to use the generated methods
  #  from the code generator, e.g. var context = new GameContext();
  abstract class Context
    spoved_logger

    protected property creation_index : Int32
    protected setter context_info : Entitas::Context::Info
    protected getter entities = Array(Entitas::Entity).new
    protected property reusable_entities = Array(Entitas::Entity).new
    protected property retained_entities = Array(Entitas::Entity).new
    protected property entities_cache : Array(Entitas::Entity)? = Array(Entitas::Entity).new

    protected property groups : Hash(String, Entitas::Group) = Hash(String, Entitas::Group).new
    protected property groups_for_index : Array(Array(::Entitas::Group))

    # component_pools is set by the context which created the entity and is used to reuse removed components.
    # Removed components will be pushed to the componentPool. Use entity.CreateComponent(index, type) to get
    # a new or reusable component from the componentPool. Use entity.GetComponentPool(index) to get a
    # componentPool for a specific component index.
    getter component_pools : Array(::Entitas::ComponentPool)

    accept_events OnEntityCreated, OnEntityWillBeDestroyed, OnEntityDestroyed, OnGroupCreated
    emits_events OnEntityCreated, OnEntityWillBeDestroyed, OnEntityDestroyed, OnGroupCreated,
      OnComponentAdded, OnComponentRemoved, OnComponentReplaced,
      OnEntityReleased, OnDestroyEntity

    def initialize(
      @creation_index : Int32 = 0,
      context_info : Entitas::Context::Info? = nil
    )
      set_cache_hooks

      @context_info = context_info || create_default_context_info
      @component_pools = Array(::Entitas::ComponentPool).new(total_components) do
        ::Entitas::ComponentPool.new
      end

      @groups_for_index = Array(Array(Group)).new(total_components) do
        Array(Group).new
      end

      if self.context_info.component_names.size != self.total_components
        raise Error::Info.new(self, self.context_info)
      end
    end

    # Resets the context (destroys all entities and resets creationIndex back to 0).
    def reset
      destroy_all_entities
      reset_creation_index

      self.on_entity_created_event_cache = nil
      self.on_entity_will_be_destroyed_event_cache = nil
      self.on_entity_destroyed_event_cache = nil
      self.on_group_created_event_cache = nil
    end

    ############################
    # Abstract functions
    ############################

    abstract def total_components : Int32
    abstract def klass_to_index(klass) : Int32
    abstract def entity_factory : Entitas::Entity

    ############################
    # ComponentPool functions
    ############################

    # Returns the `ComponentPool` for the specified component index. `component_pools` is set by the context which
    # created the entity and is used to reuse removed components. Removed components will be pushed to the
    # componentPool. Use entity.create_component(index, type) to get a new or reusable component
    # from the `ComponentPool`.
    def component_pool(index : Int32) : ComponentPool
      self.component_pools[index] = ComponentPool.new unless self.component_pools[index]?
      self.component_pools[index]
    end

    # Clears the `ComponentPool` at the specified index.
    def clear_component_pool(index : Int32)
      component_pools[index].clear
    end

    def clear_component_pool(index : ::Entitas::Component.class)
      component_pool(klass_to_index(index)).clear
    end

    # Clears all `ComponentPool`s.
    def clear_component_pools
      component_pools.each do |pool|
        pool.clear
      end
    end

    ############################
    # Context::Info functions
    ############################

    private def create_default_context_info : Entitas::Context::Info
      logger.debug "Creating default context", "Context"

      component_names = Array(String).new
      prefix = "Index "
      total_components.times do |i|
        component_names << prefix + i.to_s
      end

      Entitas::Context::Info.new("Unnamed Context",
        ::Entitas::Component::COMPONENT_NAMES,
        ::Entitas::Component::COMPONENT_KLASSES)
    end

    def context_info : ::Entitas::Context::Info
      @context_info ||= create_default_context_info
    end

    # The contextInfo contains information about the context.
    # It's used to provide better error messages.
    def info : ::Entitas::Context::Info
      self.context_info
    end

    ############################
    # Entity functions
    ############################

    # Returns the total number of `Entitas::Entity` in this `Context`
    def size
      self.entities.size
    end

    # See `size`
    def count
      self.size
    end

    # Creates a new entity or gets a reusable entity from the internal ObjectPool for entities.
    def create_entity : ::Entitas::Entity
      logger.debug "Creating new entity", self.class
      entity = if self.reusable_entities.size > 0
                 e = self.reusable_entities.pop
                 logger.debug "Reusing entity: #{e}", self.to_s
                 e.reactivate(self.creation_index)
                 self.creation_index += 1
                 e
               else
                 e = self.entity_factory
                 logger.debug "Created new entity: #{e}", self.to_s
                 e.init(self.creation_index, self.context_info, self.aerc_factory(e))
                 self.creation_index += 1
                 e
               end

      self.entities << entity

      entity.retain(self)
      set_entity_event_hooks(entity)

      self.entities_cache = nil

      emit_event OnEntityCreated, self, entity
      entity
    end

    def aerc_factory(entity : Entitas::Entity) : Entitas::SafeAERC
      Entitas::SafeAERC.new(entity)
    end

    # Destroys all entities in the context.
    # Throws an exception if there are still retained entities.
    def destroy_all_entities
      self.entities.each &.destroy!
      self.entities.clear

      if retained_entities.size != 0
        raise Error::StillHasRetainedEntities.new self, retained_entities
      end
    end

    # Determines whether the context has the specified entity.
    def has_entity?(entity : Entitas::Entity) : Bool
      self.entities.includes?(entity)
    end

    # Returns all entities which are currently in the context.
    def get_entities : Array(Entitas::Entity)
      @entities_cache ||= entities.dup
    end

    # TODO: add_entity_index
    # TODO: get_entity_index

    # Resets the creationIndex back to 0.
    def reset_creation_index
      self.creation_index = 0
    end

    ############################
    # Event functions
    ############################

    def on_component_added(event : Entitas::Events::OnComponentAdded)
      update_groups_component_added_or_removed(event.entity, event.index, event.component)
    end

    def on_component_removed(event : Entitas::Events::OnComponentRemoved)
      update_groups_component_added_or_removed(event.entity, event.index, event.component)
    end

    def on_component_replaced(event : Entitas::Events::OnComponentReplaced)
      update_groups_component_replaced(event.entity, event.index, event.prev_component, event.new_component)
    end

    def on_entity_released(event : Entitas::Events::OnEntityReleased)
      logger.info "Processing OnEntityReleased: #{event}"
      entity = event.entity

      if entity.enabled?
        raise Entity::Error::IsNotDestroyedException.new "Cannot release #{entity}!"
      end

      entity.remove_all_on_entity_released_handlers

      self.retained_entities.delete(entity)
      self.reusable_entities << entity
    end

    def on_destroy_entity(event : Entitas::Events::OnDestroyEntity)
      entity = event.entity
      self.entities.delete(entity)
      self.entities_cache = nil

      emit_event OnEntityWillBeDestroyed, self, entity
      entity.internal_destroy!
      emit_event OnEntityDestroyed, self, entity

      if entity.retain_count == 1
        # Can be released immediately without
        # adding to retained_entities

        entity.on_entity_released_event_hooks.delete(on_entity_released_event_cache)

        self.reusable_entities << entity
        entity.release(self)
        entity.remove_all_on_entity_released_handlers
      else
        self.retained_entities << entity
        entity.release(self)
      end
    end

    # Removes all event handlers
    # OnEntityCreated, OnEntityWillBeDestroyed,
    # OnEntityDestroyed and OnGroupCreated
    def remove_all_event_handlers
      self.clear_on_entity_created_event_hooks
      self.clear_on_entity_will_be_destroyed_event_hooks
      self.clear_on_entity_destroyed_event_hooks
      self.clear_on_group_created_event_hooks
    end

    ############################
    # Misc functions
    ############################

    def to_s
      info.name
    end
  end
end
