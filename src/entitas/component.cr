require "./context"

module Entitas
  abstract class Component
    # The framework will make sure that only one instance of a unique component can be present in your context
    macro is_unique
      @@is_unique = true
    end

    # Will create getter/setter for the provided `var`, ensuring its type
    macro prop(var, kype, **kwargs)
      {% if kwargs[:default] %}
        @{{ var.id }} = {{ kwargs[:default] }}
      {% end %}

      def set_{{ var.id }}(value : {{kype}})
        @{{ var.id }} = value
      end

      def get_{{ var.id }} : {{kype}} | Nil
        @{{ var.id }}
      end
    end

    @@is_unique = false

    # Class method to indicate if this component is unique
    def self.is_unique?
      @@is_unique
    end

    # Will return true if the class is a unique component for a context
    def component_is_unique?
      self.class.is_unique?
    end

    # Component error class raised when an issue is encountered
    class Error < Exception
    end
  end
end
