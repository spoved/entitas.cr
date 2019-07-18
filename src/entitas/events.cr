require "./macros"

create_event EntityCreated, {context: Context, entity: Entity}
create_event EntityWillBeDestroyed, {context: Context, entity: Entity}
create_event EntityDestroyed, {context: Context, entity: Entity}
create_event EntityReleased, {entity: Entity}
create_event EntityChanged, {entity: Entity, index: Int32, component: Entitas::Component?}

create_event ComponentAdded, {entity: Entity, index: Int32, component: Entitas::Component}
create_event ComponentRemoved, {entity: Entity, index: Int32, component: Entitas::Component?}
create_event ComponentReplaced, {entity: Entity, index: Int32, prev_component: Entitas::Component?, new_component: Entitas::Component?}

create_event DestroyEntity, {entity: Entity}

create_event GroupCreated, {context: Context, entity: Entity}

module ::Entitas::Events
  macro finished
    {% begin %}
    {% events = [] of ASTNode %}
    {% for name in @type.constants %}
      {% if name.id =~ /^On.*$/ %}
      {% events << name %}
      {% end %}
    {% end %}

    module Helper
      {% for name in events %}
      getter {{name.id.underscore.id}}_events : Array(Proc({{name.id}}, Nil)) = Array(Proc({{name.id}}, Nil)).new
      getter {{name.id.underscore.id}}_event_cache : Proc({{name.id}}, Nil)? = nil

      def clear_{{name.id.underscore.id}}_event_hooks : Nil
        self.{{name.id.underscore.id}}_events.clear
      end
      {% end %}

      def emit_event(event)
        logger.warn "Emiting event #{event.class}", self.to_s
        {% begin %}
        case event
        {% for name in events %}
        when ::Entitas::Events::{{name.id}}
          self.{{name.underscore.id}}_events.each &.call(event)
        {% end %}
        else
          logger.error("Unhandled event #{event.class}", self.class)
          raise Error.new "Unhandled event #{event.class}"
        end
        {% end %}
      end

      def clear_event_hooks
        {% for name in events %}
        self.{{name.underscore.id}}_events.clear
        {% end %}
      end
    end

    {% end %}
  end
end
