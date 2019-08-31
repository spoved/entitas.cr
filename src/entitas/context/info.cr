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
    end
  end
end
