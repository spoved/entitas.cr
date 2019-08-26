require "./component/*"

class Entitas::Component
  macro inherited
    module Helper; end
    inject_component_macd Entitas::Entity, {{@type.name.id}}
  end
end
