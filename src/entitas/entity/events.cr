require "../component"
require "../entity"
require "../macros"

module Entitas
  class Entity
    module Events
      create_event ComponentAdded, {entity: Entity, index: Int32, component: Entitas::Component}
      create_event ComponentRemoved, {entity: Entity, index: Int32, component: Entitas::Component?}
      create_event ComponentReplaced, {entity: Entity, index: Int32, prev_component: Entitas::Component?, new_component: Entitas::Component?}
      create_event EntityReleased, {entity: Entity}
      create_event EntityChanged, {entity: Entity, index: Int32, component: Entitas::Component?}
      create_event DestroyEntity, {entity: Entity}

      def remove_all_on_entity_released_handlers
        self.on_entity_released_events.clear
      end

      macro finished

        def clear_event_hooks
          {% for subc in @type.constants %}
          self.{{subc.underscore.id}}_events.clear
          {% end %}
        end

        def emit_event(event)
          logger.warn "Emiting event #{event.class}", self.to_s

          case event
          {% for subc in @type.constants %}
          when {{subc}}
            self.{{subc.underscore.id}}_events.each &.call(event)
          {% end %}
          else
            logger.error("Unhandled event #{event.class}",  "Entitas::Entity::Events")
            exit
            raise Error.new "Unhandled event #{event.class}"
          end
        end
      end
    end
  end
end
