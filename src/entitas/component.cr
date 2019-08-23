require "./macros/component"

module Entitas
  abstract class Component
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    # Component error class raised when an issue is encountered
    class Error < Exception
    end

    # Will return true if the class is a unique component for a context
    def component_is_unique?
      self.class.is_unique?
    end
  end
end
