require "spoved/logger"
require "./events"
require "./group/*"
require "./helpers/entities"

module Entitas
  class Group
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    accept_events OnEntityAdded, OnEntityRemoved, OnEntityUpdated

    include Entitas::Helper::Entities

    protected property single_entitie_cache : Entitas::Entity?
    protected property to_string_cache : String?

    protected getter matcher : Entitas::Matcher

    def initialize(@matcher : Entitas::Matcher)
    end

    # This is used by the context to manage the group.
    def handle_entity_silently(entity : Entity)
      {% if !flag?(:disable_logging) %}logger.debug("Silently handling entity : #{entity}", self.to_s){% end %}

      if self.matcher.matches?(entity)
        add_entity_silently(entity)
      else
        remove_entity_silently(entity)
      end
    end

    def handle_entity(entity : Entity) : ::Entitas::Events::GroupChanged
      {% if !flag?(:disable_logging) %}logger.debug("Handling entity : #{entity}", self.to_s){% end %}

      if self.matcher.matches?(entity)
        add_entity_silently(entity) ? ::Entitas::Events::OnEntityAdded : nil
      else
        remove_entity_silently(entity) ? ::Entitas::Events::OnEntityRemoved : nil
      end
    end

    # This is used by the context to manage the group.
    def handle_entity(entity : Entity, index : Int32, component : Entitas::Component)
      {% if !flag?(:disable_logging) %}logger.debug("Context handle entity : #{entity}", self.to_s){% end %}

      if self.matcher.matches?(entity)
        add_entity(entity, index, component)
      else
        remove_entity(entity, index, component)
      end
    end

    # This is used by the context to manage the group.
    def update_entity(entity : Entitas::Entity, index : Int32, prev_component : Entitas::Component?, new_component : Entitas::Component?)
      {% if !flag?(:disable_logging) %}logger.debug("Update entity : #{entity}", self.to_s){% end %}

      if has_entity?(entity)
        emit_event OnEntityRemoved, self, entity, index, prev_component
        emit_event OnEntityAdded, self, entity, index, new_component
        emit_event OnEntityUpdated, self, entity, index, prev_component, new_component
      end
    end

    # Removes all event handlers from this group.
    # Keep in mind that this will break reactive systems and
    # entity indices which rely on this group.
    #
    # Removes: `OnEntityRemoved`, `OnEntityAdded`, and `OnEntityUpdated`
    def remove_all_event_handlers
      {% if !flag?(:disable_logging) %}logger.debug("Remove all event handlers", self.to_s){% end %}

      self.clear_on_entity_removed_event_hooks
      self.clear_on_entity_added_event_hooks
      self.clear_on_entity_updated_event_hooks
    end

    def add_entity_silently(entity : Entity) : Entity | Bool
      {% if !flag?(:disable_logging) %}logger.debug("Silently adding entity : #{entity}", self.to_s){% end %}

      if entity.enabled? && self.entities.add?(entity)
        self.entities_cache = nil
        self.single_entitie_cache = nil
        entity.retain(self)

        return entity
      end

      false
    end

    def add_entity(entity : Entity, index : Int32, component : Component)
      {% if !flag?(:disable_logging) %}logger.warn("Adding entity : #{entity}", self.to_s){% end %}
      if add_entity_silently(entity)
        emit_event OnEntityAdded, self, entity, index, component
      end
    end

    private def _remove_entity(entity : Entity)
      self.entities.delete(entity)
      self.entities_cache = nil
      self.single_entitie_cache = nil
    end

    def remove_entity_silently(entity : Entity) : Entity?
      {% if !flag?(:disable_logging) %}logger.debug("Silently removing entity : #{entity}", self.to_s){% end %}

      if self.has_entity?(entity)
        self._remove_entity(entity)

        entity.release(self)
        entity
      else
        nil
      end
    end

    def remove_entity(entity : Entity, index : Int32, component : Component) : Entity?
      {% if !flag?(:disable_logging) %}logger.debug("Removing entity : #{entity}", self.to_s){% end %}

      if self.has_entity?(entity)
        self._remove_entity(entity)

        emit_event OnEntityRemoved, self, entity, index, component

        entity.release(self)
        entity
      else
        nil
      end
    end

    def get_entities(buff : Array(Entitas::Entity)) : Array(Entitas::Entity)
      buff.clear
      buff.concat entities
      buff
    end

    # Returns the only entity in this group. It will return null
    # if the group is empty. It will throw an exception if the group
    # has more than one entity.
    def get_single_entity : Entitas::Entity?
      if single_entitie_cache.nil?
        if size == 1
          self.single_entitie_cache = entities.first?
        elsif size == 0
          return nil
        else
          raise Entitas::Group::Error::SingleEntity.new
        end
      end

      single_entitie_cache
    end

    ############################
    # Misc funcs
    ############################

    def to_s(io)
      io << "Group("
      matcher.to_s(io)
      io << ")"
    end
  end
end
