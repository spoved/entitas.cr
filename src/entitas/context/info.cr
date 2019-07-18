require "../component"

module Entitas
  abstract class Context
    class Info
      getter name : String
      getter component_names : Array(String)
      getter component_types : Array(Component.class)?

      def initialize(@name,
                     @component_names = ::Entitas::Component::COMPONENT_MAP.keys.map &.to_s,
                     @component_types = ::Entitas::Component::COMPONENT_MAP.keys)
      end
    end
  end
end
