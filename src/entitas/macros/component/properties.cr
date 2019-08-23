class Entitas::Component
  # Will create getter/setter for the provided `var`, ensuring its type
  macro prop(var, kype, **kwargs)
    {% if kwargs[:default] %}
      property {{ var.id }} : {{kype}} = {{ kwargs[:default] }}

      # This is a private methods used for code generation
      private def _entitas_set_{{ var.id }}(value : {{kype}} = {{ kwargs[:default] }})
        @{{ var.id }} = value
      end
    {% else %}
      property {{ var.id }} : {{kype}}? = nil

      # This is a private methods used for code generation
      private def _entitas_set_{{ var.id }}(value : {{kype}})
        @{{ var.id }} = value
      end
    {% end %}
  end
end
