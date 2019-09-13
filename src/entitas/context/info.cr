require "../component"

module Entitas
  abstract class Context(TEntity)
    class Info
      getter name : String
      getter component_names : Array(String)
      getter component_types : Array(Entitas::Component::ComponentTypes)

      def initialize(
        @name,
        @component_names = Entitas::Component::COMPONENT_NAMES,
        @component_types = Entitas::Component::COMPONENT_KLASSES
      )
      end

      def to_json(json)
        json.object do
          json.field "name", name
          json.field "component_names", component_names
          json.field "component_types", component_types.map &.to_s
        end
      end
    end
  end
end
