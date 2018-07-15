require "../component"

module Entitas
  abstract class Context
    class Info
      getter name : String
      getter component_names : Array(String)
      getter component_types : Array(Component.class)

      def initialize(@name, @component_names, @component_types)
      end
    end
  end
end
