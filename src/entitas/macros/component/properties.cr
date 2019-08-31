class Entitas::Component
  # Will create getter/setter for the provided `var`, ensuring its type
  macro prop(var, kype, **kwargs)
    {% if kwargs[:default] %}
      property {{ var.id }} : {{kype}} = {{ kwargs[:default] }}

      # :nodoc:
      # This is a private methods used for code generation
      private def _entitas_set_{{ var.id }}(value : {{kype}} = {{ kwargs[:default] }})
        @{{ var.id }} = value
      end
    {% else %}
      property {{ var.id }} : {{kype}}? = nil

      # :nodoc:
      # This is a private methods used for code generation
      private def _entitas_set_{{ var.id }}(value : {{kype}})
        @{{ var.id }} = value
      end
    {% end %}
  end
end

macro define_property(var, kype, **kwargs)
  Entitas::Component.prop({{var}}, {{kype}}, {{**kwargs}})
end

macro property_alias(var, kype, **kwargs)
  {% if kwargs[:default] %}
    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}} = {{ kwargs[:default] }})
      self.{{ var.id }} = value
    end
  {% else %}
    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}})
      self.{{ var.id }} = value
    end
  {% end %}
end
