require "./component"
require "./component/helper"
require "./entity"
require "./context/*"
require "spoved/logger"

module Entitas
  # A context manages the lifecycle of entities and groups.
  #  You can create and destroy entities and get groups of entities.
  #  The prefered way to create a context is to use the generated methods
  #  from the code generator, e.g. var context = new GameContext();
  abstract class Context
    spoved_logger

    # include Entitas::Entity::Events
    include Entitas::Component::Helper
    include Entitas::Context::Events

    protected property creation_index : Int32
    protected property aerc_factory : AERCFactory
    protected property entity_factory : EntityFactory
    protected setter context_info : Context::Info

    getter entities = Array(Entity).new
    protected property reusable_entities = Array(Entity).new
    protected property retained_entities = Array(Entity).new

    protected property entities_cache = Array(Entity).new

    getter on_entity_changed_cache : Proc(Entitas::Entity::OnEntityChanged, Nil)
    getter on_component_replaced_cache : Proc(Entitas::Entity::OnComponentReplaced, Nil)
    getter on_entity_released_cache : Proc(Entitas::Entity::OnEntityReleased, Nil)
    getter on_destroy_entity_cache : Proc(Entitas::Entity::OnDestroyEntity, Nil)

    def initialize(
      # @total_components : Int32 = ::Entitas::Component::TOTAL_COMPONENTS,
      @creation_index : Int32 = 0,
      context_info : Entitas::Context::Info? = nil,
      @aerc_factory : AERCFactory = AERCFactory.new { |entity| Entitas::SafeAERC.new(entity) },
      @entity_factory : EntityFactory = EntityFactory.new { Entitas::Entity.new }
    )
      @on_entity_changed_cache = ->on_entity_changed(Entitas::Entity::Events::OnEntityChanged)
      @on_component_replaced_cache = ->on_component_replaced(Entitas::Entity::Events::OnComponentReplaced)
      @on_entity_released_cache = ->on_entity_released(Entitas::Entity::Events::OnEntityReleased)
      @on_destroy_entity_cache = ->on_destroy_entity(Entitas::Entity::Events::OnDestroyEntity)

      @context_info = context_info || create_default_context_info
      # @component_pools = Array(ComponentPool).new(total_components)

      if self.context_info.component_names.size != self.total_components
        raise Error::Info.new(self, self.context_info)
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
      logger.debug "Creating default context", "Context"

      component_names = Array(String).new
      prefix = "Index "
      total_components.times do |i|
        component_names << prefix + i.to_s
      end

      Entitas::Context::Info.new("Unnamed Context", component_names, ::Entitas::Component::COMPONENT_MAP.keys)
    end

    def context_info : Context::Info
      @context_info ||= create_default_context_info
    end

    # The contextInfo contains information about the context.
    # It's used to provide better error messages.
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

    # See `size`
    def count
      self.size
    end

    # Creates a new entity or gets a reusable entity from the internal ObjectPool for entities.
    def create_entity : Entitas::Entity
      logger.debug "Creating new entity", self.class
      entity = if self.reusable_entities.size > 0
                 e = self.reusable_entities.pop
                 logger.debug "Reusing entity: #{e}", self.to_s
                 e.reactivate(self.creation_index)
                 self.creation_index += 1
                 e
               else
                 e = self.entity_factory.call
                 logger.debug "Created new entity: #{e}", self.to_s
                 e.init(self.creation_index, self.context_info, self.aerc_factory.call(e))
                 self.creation_index += 1
                 e
               end

      self.entities << entity

      entity.retain(self)
      self.entities_cache.clear

      # TODO: Finish rest of hooks
      # entity.on_component_added_event
      # entity.on_component_removed_event
      # entity.on_component_replaced_event

      entity.on_entity_released &on_entity_released_cache.as(Proc(Entitas::Entity::OnEntityReleased, Nil))
      entity.on_destroy_entity &on_destroy_entity_cache.as(Proc(Entitas::Entity::OnDestroyEntity, Nil))

      entity
    end

    # Determines whether the context has the specified entity.
    def has_entity?(entity : Entitas::Entity) : Bool
      self.entities.includes?(entity)
    end

    ############################
    # Event functions
    ############################

    def on_entity_changed(event : Entitas::Entity::Events::OnEntityChanged)
    end

    def on_component_replaced(event : Entitas::Entity::Events::OnComponentReplaced)
    end

    def on_entity_released(event : Entitas::Entity::Events::OnEntityReleased)
      entity = event.entity
      if entity.enabled?
        raise Entity::Error::IsNotDestroyedException.new "Cannot release #{entity}!"
      end

      entity.remove_all_on_entity_released_handlers
      self.retained_entities.delete(entity)
      self.reusable_entities << entity
    end

    def on_destroy_entity(event : Entitas::Entity::Events::OnDestroyEntity)
      entity = event.entity
      self.entities.delete(entity)
      self.entities_cache.clear

      emit_event OnEntityWillBeDestroyed.new(self, entity)
      entity._destroy!
      emit_event OnEntityDestroyed.new(self, entity)

      if entity.retain_count == 1
        # Can be released immediately without
        # adding to retained_entities

        entity.on_entity_released_events.delete(on_entity_released_cache)

        self.reusable_entities << entity
        entity.release(self)
        entity.remove_all_on_entity_released_handlers
      else
        self.retained_entities << entity
        entity.release(self)
      end
    end

    def remove_all_event_handlers
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
