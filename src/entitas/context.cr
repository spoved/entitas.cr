require "./*"
require "./component/helper"
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

    protected property creation_index : Int32
    protected property aerc_factory : AERCFactory
    protected property entity_factory : EntityFactory
    protected setter context_info : Context::Info
    protected getter entities = Array(Entity).new
    protected property reusable_entities = Array(Entity).new
    protected property retained_entities = Array(Entity).new
    protected property entities_cache : Array(Entity)? = Array(Entity).new

    emits_events OnEntityCreated, OnEntityWillBeDestroyed, OnEntityDestroyed, OnGroupCreated

    protected property on_component_added_event_cache : Proc(Events::OnComponentAdded, Nil)? = nil
    protected property on_component_removed_event_cache : Proc(Events::OnComponentRemoved, Nil)? = nil
    protected property on_component_replaced_event : Proc(Events::OnComponentReplaced, Nil)? = nil
    protected property on_entity_released_cache : Proc(Events::OnEntityReleased, Nil)? = nil
    protected property on_destroy_entity_cache : Proc(Events::OnDestroyEntity, Nil)? = nil

    def initialize(
      @creation_index : Int32 = 0,
      context_info : Entitas::Context::Info? = nil,
      @aerc_factory : AERCFactory = AERCFactory.new { |entity| Entitas::SafeAERC.new(entity) },
      @entity_factory : EntityFactory = EntityFactory.new { Entitas::Entity.new }
    )
      @on_destroy_entity_cache = ->on_destroy_entity_event(Events::OnDestroyEntity)
      @on_entity_created_event_cache = ->on_entity_created_event(Events::OnEntityCreated)
      @on_entity_will_be_destroyed_event_cache = ->on_entity_will_be_destroyed_event(Events::OnEntityWillBeDestroyed)
      @on_entity_destroyed_event_cache = ->on_entity_destroyed_event(Events::OnEntityDestroyed)
      @on_group_created_event_cache = ->on_group_created_event(Events::OnGroupCreated)

      @context_info = context_info || create_default_context_info

      if self.context_info.component_names.size != self.total_components
        raise Error::Info.new(self, self.context_info)
      end
    end

    # Resets the context (destroys all entities and resets creationIndex back to 0).
    def reset
      destroy_all_entities
      reset_creation_index

      self.on_entity_created_event_cache = null
      self.on_entity_will_be_destroyed_event_cache = null
      self.on_entity_destroyed_event_cache = null
      self.on_group_created_event_cache = null
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
      set_entity_event_hooks(entity)

      self.entities_cache = nil

      emit_event OnEntityCreated, self, entity

      entity
    end

    private def set_entity_event_hooks(entity)
      if !on_component_added_event_cache.nil?
        entity.on_component_added &on_component_added_event_cache.as(Proc(Events::OnComponentAdded, Nil))
      end

      if !on_component_removed_event_cache.nil?
        entity.on_component_removed &on_component_removed_event_cache.as(Proc(Events::OnComponentRemoved, Nil))
      end

      if !on_component_replaced_event.nil?
        entity.on_component_replaced &on_component_replaced_event.as(Proc(Events::OnComponentReplaced, Nil))
      end

      if !on_entity_released_cache.nil?
        entity.on_entity_released &on_entity_released_cache.as(Proc(Events::OnEntityReleased, Nil))
      end

      if !on_destroy_entity_cache.nil?
        entity.on_destroy_entity &on_destroy_entity_cache.as(Proc(Events::OnDestroyEntity, Nil))
      end
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
    def get_entities : Array(Entity)
      @entities_cache ||= entities.dup
    end

    # TODO: get_group
    # TODO: add_entity_index
    # TODO: get_entity_index

    # Resets the creationIndex back to 0.
    def reset_creation_index
      self.creation_index = 0
    end

    ############################
    # Event functions
    ############################

    def on_entity_changed(event : Events::OnEntityChanged)
    end

    def on_component_added_event(event : Events::OnComponentAdded)
    end

    def on_component_replaced(event : Events::OnComponentReplaced)
    end

    def on_entity_released(event : Events::OnEntityReleased)
      entity = event.entity
      if entity.enabled?
        raise Entity::Error::IsNotDestroyedException.new "Cannot release #{entity}!"
      end

      entity.remove_all_on_entity_released_handlers
      self.retained_entities.delete(entity)
      self.reusable_entities << entity
    end

    def on_destroy_entity_event(event : Events::OnDestroyEntity)
      entity = event.entity
      self.entities.delete(entity)
      self.entities_cache = nil

      emit_event OnEntityWillBeDestroyed, self, entity
      entity._destroy!
      emit_event OnEntityDestroyed, self, entity

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
