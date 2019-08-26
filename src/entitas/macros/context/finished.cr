class Entitas::Context
  macro finished
    {% begin %}
    private def set_entity_event_hooks(entity)
      {% for meth in @type.methods %}{% if meth.name =~ /^(.*)_event_cache$/ %}
      {% ent_meth_name = meth.name.gsub(/_event_cache$/, "").id %}
      if !{{meth.name.id}}.nil?
        {% if !flag?(:disable_logging) %}logger.debug("Setting {{ent_meth_name.camelcase.id}} hook for #{entity}", self.class){% end %}
        entity.{{ent_meth_name}} &@{{meth.name.id}}.as(Proc(Entitas::Events::{{ent_meth_name.camelcase.id}}, Nil))
      end
      {% end %}{% end %}
    end

    private def set_cache_hooks
      {% for meth in @type.methods %}{% if meth.name =~ /^(.*)_event_cache$/ %}
      {% ent_meth_name = meth.name.gsub(/_event_cache$/, "").id %}
      @{{meth.name.id}} = ->{{ent_meth_name.id}}(Entitas::Events::{{ent_meth_name.camelcase.id}})
      {% end %}{% end %}
    end

    {% end %}
  end
end
