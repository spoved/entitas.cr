# Will create getter/setter for the provided `var`, ensuring its type
macro prop(var, kype, **kwargs)
  {% if kwargs[:default] %}
    setter {{ var.id }} : {{kype}} = {{ kwargs[:default] }}

    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}} = {{ kwargs[:default] }})
      @{{ var.id }} = value
    end
  {% elsif kwargs[:not_nil] %}
    setter {{ var.id }} : {{kype}}

    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}})
      @{{ var.id }} = value
    end

    {% if kwargs[:method] %}
      # :nodoc:
      private def _entitas_{{ var.id }}_method : {{kype}}
        {{kwargs[:method]}}
      end
    {% end %}

  {% else %}
    setter {{ var.id }} : {{kype}}? = nil

    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}})
      @{{ var.id }} = value
    end
  {% end %}

  def {{ var.id }}? : Bool
    !@{{ var.id }}.nil?
  end

  {% if kwargs[:index] %}@[::EntityIndex(var: {{ var.id }}, type: {{kype}})]{% end %}
  def {{ var.id }} : {{kype}}
    if @{{ var.id }}.nil?
      raise Exception.new("{{ var.id }} is nil! Check before calling!")
    else
      @{{ var.id }}.as({{kype}})
    end
  end


  {% if kwargs[:index] %}
    Entitas::Contexts.create_contexts_index_name({{@type}}, {{var.id}})
  {% end %}
end

macro property_alias(var, kype, **kwargs)
  {% if kwargs[:default] %}
    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}} = {{ kwargs[:default] }})
      self.{{ var.id }} = value
    end

  {% elsif kwargs[:not_nil] %}
    setter {{ var.id }} : {{kype}}

    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}})
      @{{ var.id }} = value
    end

    {% if kwargs[:method] %}
      # :nodoc:
      private def _entitas_{{ var.id }}_method : {{kype}}
        {{kwargs[:method]}}
      end
    {% end %}

  {% else %}
    # :nodoc:
    # This is a private methods used for code generation
    private def _entitas_set_{{ var.id }}(value : {{kype}})
      self.{{ var.id }} = value
    end
  {% end %}

  {% if kwargs[:index] %}
    Entitas::Contexts.create_contexts_index_name({{@type}}, {{var.id}})
  {% end %}
end
