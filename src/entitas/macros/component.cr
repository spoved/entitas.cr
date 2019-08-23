require "./component/*"

class Entitas::Component
  macro inherited
    inject_component_macd ::Entitas::Entity, {{@type.name.id}}
  end
end
