class ::Entitas::Contexts
  macro create_contexts_index_name(comp, var)
    {% index_name = (comp.id.gsub(/::/, "") + "EntityIndices#{var.name.camelcase.id}").underscore.upcase %}

    class ::Entitas::Contexts
      # `EntityIndex` name for `{{comp}}` property `{{var}}`
      {{index_name.id}} = {{index_name.stringify}}
    end
  end
end

class Entitas::Context(TEntity)
  macro finished
    ### Generate event methods

    private def set_entity_event_hooks(entity)
      {% for meth in @type.methods %}
      {% if meth.annotation(EventHandler) %}
        {% if flag?(:entitas_enable_logging) %}Log.debug {"#{self} - Adding {{meth.name.camelcase.id}} hook for #{entity} to {{meth.name.id}}"}{% end %}
        entity.{{meth.name.id}} &->{{meth.name.id}}(Entitas::Events::{{meth.name.camelcase.id}})
      {% end %}{% end %}
    end
  end
end
