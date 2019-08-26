class Entitas::Entity
  macro create_entity_for_context(context_name, components)
    class ::{{context_name.id}}Entity < Entitas::Entity
      Entitas::Component.create_instance_helpers({{context_name}}Context)
    end
  end
end
