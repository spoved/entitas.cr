class Entitas::Entity
  macro create_entity_for_context(context_name, components)
    class ::{{context_name.id}}Entity < Entitas::Entity
      Entitas::Component.create_instance_helpers({{context_name}}Context)
    end

    {% for component_name in components %}
      Entitas::Component.inject_component_macd(::{{context_name.id}}Entity, {{component_name}})
    {% end %}
  end
end
