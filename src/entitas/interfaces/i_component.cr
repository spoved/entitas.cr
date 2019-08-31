require "../macros/component/properties"

module Entitas::IComponent
  {% if !flag?(:disable_logging) %}spoved_logger{% end %}

  # Will return true if the class is a unique component for a context
  abstract def is_unique? : Bool
  abstract def init(**args)
  abstract def reset

  macro included
    Entitas::Component.initializers
  end
end
