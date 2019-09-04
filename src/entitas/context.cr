require "spoved/logger"

require "./error"
require "./interfaces/i_context"
require "./macros/generator"
require "./context/*"
require "./events"
require "./helpers/entities"
require "./helpers/component_pools"

module Entitas
  # A context manages the lifecycle of entities and groups.
  #  You can create and destroy entities and get groups of entities.
  #  The prefered way to create a context is to use the generated methods
  #  from the code generator, e.g. var context = new GameContext();
  abstract class Context(TEntity)
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    include IContext

    include Entitas::Helper::Entities(TEntity)
    include Entitas::Helper::ComponentPools

    protected property creation_index : Int32
    protected setter context_info : Entitas::Context::Info

    protected property reusable_entities = Array(TEntity).new
    protected property retained_entities = Set(IEntity).new
    protected property component_names_cache : Array(String) = Array(String).new

    emits_events OnEntityCreated, OnEntityWillBeDestroyed, OnEntityDestroyed, OnGroupCreated,
      OnComponentAdded, OnComponentRemoved, OnComponentReplaced,
      OnEntityReleased, OnDestroyEntity

    def initialize(
      @creation_index : Int32 = 0,
      context_info : Entitas::Context::Info? = nil
    )
      set_cache_hooks

      @context_info = context_info || create_default_context_info
      @component_pools = Array(Entitas::ComponentPool).new(total_components) do
        Entitas::ComponentPool.new
      end

      @groups_for_index = Array(Set(Group(TEntity))).new(total_components) do
        Set(Group(TEntity)).new
      end

      if self.context_info.component_names.size != self.total_components
        raise Error::Info.new(self, self.context_info)
      end

      call_post_constructors
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
    # Context::Info functions
    ############################

    abstract def create_default_context_info : Entitas::Context::Info

    def context_info : Entitas::Context::Info
      @context_info ||= self.create_default_context_info
    end

    # The contextInfo contains information about the context.
    # It's used to provide better error messages.
    def info : Entitas::Context::Info
      self.context_info
    end

    ############################
    # Entity functions
    ############################

    # Creates a new entity or gets a reusable entity from the internal ObjectPool for entities.
    def create_entity : TEntity
      {% if !flag?(:disable_logging) %}logger.debug("Creating new entity", self.class){% end %}
      entity = if self.reusable_entities.size > 0
                 e = self.reusable_entities.pop
                 {% if !flag?(:disable_logging) %}logger.debug("Reusing entity: #{e}", self.to_s){% end %}
                 e.reactivate(self.creation_index, self.context_info)
                 self.creation_index += 1
                 e
               else
                 e = self.entity_factory
                 {% if !flag?(:disable_logging) %}logger.debug("Created new entity: #{e}", self.to_s){% end %}
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

    def aerc_factory(entity : TEntity) : Entitas::SafeAERC
      Entitas::SafeAERC.new(entity)
    end

    # Destroys all entities in the context.
    # Throws an exception if there are still retained entities.
    def destroy_all_entities
      self.entities.each &.destroy!
      self.entities.clear

      if retained_entities.size != 0
        raise Error::StillHasRetainedEntities.new(self, retained_entities)
      end
    end

    # Resets the creationIndex back to 0.
    def reset_creation_index
      self.creation_index = 0
    end

    ############################
    # Event functions
    ############################

    def on_component_added(event : Entitas::Events::OnComponentAdded)
      update_groups_component_added_or_removed(event.entity.as(TEntity), event.index, event.component)
    end

    def on_component_removed(event : Entitas::Events::OnComponentRemoved)
      update_groups_component_added_or_removed(event.entity.as(TEntity), event.index, event.component)
    end

    def on_component_replaced(event : Entitas::Events::OnComponentReplaced)
      update_groups_component_replaced(event.entity.as(TEntity), event.index, event.prev_component, event.new_component)
    end

    def on_entity_released(event : Entitas::Events::OnEntityReleased)
      {% if !flag?(:disable_logging) %}logger.info("Processing OnEntityReleased: #{event}"){% end %}
      entity = event.entity.as(TEntity)

      if entity.enabled?
        raise Entity::Error::IsNotDestroyedException.new "Cannot release #{entity}!"
      end

      entity.remove_all_on_entity_released_handlers

      self.retained_entities.delete(entity)
      self.reusable_entities << entity
    end

    def on_destroy_entity(event : Entitas::Events::OnDestroyEntity)
      entity = event.entity.as(TEntity)

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

    def to_s(io)
      io << self.context_info.name
    end
  end
end
