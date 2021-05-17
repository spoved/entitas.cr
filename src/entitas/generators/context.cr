require "./context/*"

class Entitas::Context(TEntity)
  macro finished
    {% if flag?(:entitas_debug_generator) %}{% puts "## Generate event methods for #{@type.id}" %}{% end %}

    private def set_entity_event_hooks(entity)
      {% for meth in @type.methods %}
      {% if meth.annotation(EventHandler) %}
        {% if flag?(:entitas_enable_logging) %}Log.debug {"#{self} - Adding {{meth.name.camelcase.id}} hook for #{entity} to {{meth.name.id}}"}{% end %}
        entity.{{meth.name.id}} &->{{meth.name.id}}(Entitas::Events::{{meth.name.camelcase.id}})
      {% end %}{% end %}
    end
  end
end
