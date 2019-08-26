require "../component"

module Entitas
  abstract class Context
    class Info
      getter name : String
      getter component_names : Array(String)
      getter component_types : Entitas::Component::KlassList

      def initialize(
        @name,
        @component_names = Entitas::Component::COMPONENT_NAMES,
        @component_types = Entitas::Component::COMPONENT_KLASSES
      )
      end
    end
  end
end
