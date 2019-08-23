require "./error"

module Entitas
  module EntityIndex
    abstract def name : String
    abstract def activate : Nil
    abstract def deactivate : Nil
  end

  abstract class Entity
    abstract class Index(TKey)
      include EntityIndex

      protected property group : Entitas::Group
      protected property get_key : Proc(Entitas::Entity, Entitas::Component?, TKey)
      protected property get_keys : Proc(Entitas::Entity, Entitas::Component?, Array(TKey))

      getter name : String | Nil

      private getter to_string_cache : String? = nil

      protected property is_single_key : Bool

      ON_ENTITY_ADDED   = ->on_entity_added
      ON_ENTITY_REMOVED = ->on_entity_removed_event_hooks

      def activate : Nil
        group.on_entity_added_event_hooks << ON_ENTITY_ADDED
        group.on_entity_removed_event_hooks << ON_ENTITY_REMOVED
      end

      def deactivate : Nil
        group.on_entity_added_event_hooks.delete ON_ENTITY_ADDED
        group.on_entity_removed_event_hooks.delete ON_ENTITY_REMOVED
        self.clear
      end

      def initialize(
        @name : String, @group : Entitas::Group,
        @get_key : Proc(Entitas::Entity, Entitas::Component?, TKey),
        @get_keys : Proc(Entitas::Entity, Entitas::Component?, Array(TKey)),
        @is_single_key
      )
      end

      def self.new(name : String, group : Entitas::Group, get_key : Proc(Entitas::Entity, Entitas::Component?, TKey))
        instance = self.class.allocate
        instance.initialize(
          name,
          group,
          get_key,
          ->(_entity : Entitas::Entity, _component : Entitas::Component?, _keys : Array(TKey)) {},
          true
        )
        instance
      end

      def self.new(name : String, group : Entitas::Group, get_keys : Proc(Entitas::Entity, Entitas::Component?, Array(TKey)))
        instance = self.class.allocate
        instance.initialize(
          name,
          group,
          ->(_entity : Entitas::Entity, _component : Entitas::Component?, _key : TKey) {},
          get_keys,
          false
        )
        instance
      end

      protected def single_key?
        @is_single_key
      end

      protected def index_entities(group : Entitas::Group)
        group.entities.each do |entity|
          if single_key?
            add_entity(self.get_key.call(entity, nil), entity)
          else
            self.get_keys.call(entity, nil).each do |key|
              add_entity(key, entity)
            end
          end
        end
      end

      protected def on_entity_added(event : Entitas::Events::OnEntityRemoved)
        if single_key?
          add_entity(self.get_key.call(event.entity, nil), event.entity)
        else
          self.get_keys.call(event.entity, nil).each do |key|
            add_entity(key, event.entity)
          end
        end
      end

      protected def on_entity_removed(event : Entitas::Events::OnEntityRemoved)
        if single_key?
          del_entity(self.get_key.call(event.entity, nil), event.entity)
        else
          self.get_keys.call(event.entity, nil).each do |key|
            del_entity(key, event.entity)
          end
        end
      end

      def finalize
        self.deactivate
      end

      def to_s(io)
        if self.to_string_cache.nil?
          self.to_string_cache = "#{self.class}(#{self.name})"
        else
          io << self.to_string_cache
        end
      end

      abstract def clear
      abstract def add_entity(key : TKey, entity : Entitas::Entity)
      abstract def del_entity(key : TKey, entity : Entitas::Entity)
    end
  end
end
