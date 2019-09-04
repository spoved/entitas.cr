class ::Entitas::Contexts
  macro create_contexts_index_name(comp, var)
    {% index_name = (comp.id.gsub(/::/, "") + "EntityIndices#{var.name.camelcase.id}").underscore.upcase %}

    class ::Entitas::Contexts
      # `EntityIndex` name for `{{comp}}` property `{{var}}`
      {{index_name.id}} = {{index_name.stringify}}
    end
  end
end
