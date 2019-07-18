require "../component"
require "../entity"
require "../macros"

module Entitas
  class Context
    module Events
      create_event EntityCreated, {context: Context, entity: Entity}
      create_event EntityWillBeDestroyed, {context: Context, entity: Entity}
      create_event EntityDestroyed, {context: Context, entity: Entity}
      create_event GroupCreated, {context: Context, entity: Entity}

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
          when {{subc.id}}
            self.{{subc.underscore.id}}_events.each &.call(event)
          {% end %}
          else
            logger.error("Unhandled event #{event.class}", "Entitas::Context::Events")
            exit
            raise Error.new "Unhandled event #{event.class}"
          end
        end
      end
    end
  end
end
