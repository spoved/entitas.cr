require "../component"
require "../entity"

module Entitas
  class Entity
    module Events
      protected getter on_component_added_event = Array(Proc(Entitas::Entity::OnComponentAdded, Nil)).new
      protected getter on_component_removed_event = Array(Proc(Entitas::Entity::OnComponentRemoved, Nil)).new
      protected getter on_component_replaced_event = Array(Proc(Entitas::Entity::OnComponentReplaced, Nil)).new
      protected getter on_entity_released_event = Array(Proc(Entitas::Entity::OnEntityReleased, Nil)).new
      protected getter on_destroy_entity_event = Array(Proc(Entitas::Entity::OnDestroyEntity, Nil)).new

      def on_component_added_event(&block : OnComponentAdded -> Nil)
        self.on_component_added_event << block
      end

      def on_component_removed_event(&block : OnComponentRemoved -> Nil)
        self.on_component_removed_event << block
      end

      def on_component_replaced_event(&block : OnComponentReplaced -> Nil)
        self.on_component_replaced_event << block
      end

      def on_entity_released_event(&block : OnEntityReleased -> Nil)
        self.on_entity_released_event << block
      end

      def on_destroy_entity_event(&block : OnDestroyEntity -> Nil)
        self.on_destroy_entity_event << block
      end

      def remove_all_on_entity_released_handlers
        self.on_entity_released_event.clear
      end

      def emit_event(event)
        case event
        when OnComponentAdded
          self.on_component_added_event.each &.call(event)
        when OnComponentRemoved
          self.on_component_removed_event.each &.call(event)
        when OnComponentReplaced
          self.on_component_replaced_event.each &.call(event)
        when OnEntityReleased
          self.on_entity_released_event.each &.call(event)
        when OnDestroyEntity
          self.on_destroy_entity_event.each &.call(event)
        else
        end
      end

      struct OnComponentAdded
        getter entity : Entity
        getter index : Int32
        getter component : Entitas::Component

        def initialize(@entity : Entity, @index : Int32,
                       @component : Entitas::Component)
        end
      end

      struct OnComponentRemoved
        getter entity : Entity
        getter index : Int32
        getter component : Entitas::Component?

        def initialize(@entity : Entity, @index : Int32,
                       @component : Entitas::Component?)
        end
      end

      struct OnComponentReplaced
        getter entity : Entity
        getter index : Int32
        getter prev_component : Entitas::Component?
        getter new_component : Entitas::Component?

        def initialize(@entity : Entity, @index : Int32,
                       @prev_component : Entitas::Component?, @new_component : Entitas::Component?)
        end
      end

      struct OnEntityReleased
        getter entity : Entity

        def initialize(@entity : Entity)
        end
      end

      struct OnDestroyEntity
        getter entity : Entity

        def initialize(@entity : Entity)
        end
      end
    end
  end
end
