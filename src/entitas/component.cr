require "./context"

annotation ::Component::Unique
end

module Entitas
  abstract class Component
    alias Property = NamedTuple(
      type: Bool.class | Float64.class | Int32.class | Int64.class | String.class | Nil.class,
      key: String,
      has_default: Bool,
      default: Bool | Float64 | Int32 | Int64 | String | Nil,
    )

    macro inherited

      annotation ::Component::{{@type.name}}
      end

      # If the component has the unique annotation,
      #   set the class method to `true`
      # The framework will make sure that only one instance of a unique component can be present in your context
      {% if @type.annotation(::Component::Unique) %}
        def self.is_unique?
          true
        end
      {% end %}

      class Entitas::Entity

        # Will return the first component that is a `{{@type.name.id}}` or `nil`
        def {{@type.name.id.downcase}} : {{@type.id}} | Nil
          comp = @components.find { |%c| %c.is_a?(::{{@type.name.id}}) }
          comp.nil? ? nil : comp.as({{@type.id}})
        end

        # Add a `{{@type.name.id}}` to the entity
        # ```
        # entity.add_{{@type.name.id.downcase}}
        # ```
        def add_{{@type.name.id.downcase}}(**args)
          component = {{@type.name.id}}.new(**args)
          check_unique_component(component) if component.component_is_unique?
          @components << component
        end


        # Delete *all* `{{@type.name.id}}` from the entity
        # ```
        # entity.del_{{@type.name.id.downcase}}
        # entity.{{@type.name.id.downcase}} # => nil
        # ```
        def del_{{@type.name.id.downcase}}
          @components.reject! { |%c| %c.is_a?(::{{@type.name.id}}) }
        end
      end

      class ::{{@type.id}}
        @@properties = Hash(Symbol, Property).new



        # When the class is finished search the method names for each setter
        # and populate the initialize arguments.
        macro finished
          def initialize(
          \{% for meth in @type.methods %}
          \{% if meth.name =~ /^_entitas_set_(.*)$/ %}
          \{% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
          \{% if meth.args[0].default_value %}
            @\{{var_name}} : \{{meth.args[0].restriction}} = \{{meth.args[0].default_value}},
          \{% else %}
            @\{{var_name}} : \{{meth.args[0].restriction}},
          \{% end %}
          \{% end %}
          \{% end %}
            )
          end
        end
      end
    end

    # Will create getter/setter for the provided `var`, ensuring its type
    macro prop(var, kype, **kwargs)

      {% if kwargs[:default] %}
        property {{ var.id }} : {{kype}} = {{ kwargs[:default] }}

        # This is a private methods used for code generation
        private def _entitas_set_{{ var.id }}(value : {{kype}} = {{ kwargs[:default] }})
          @{{ var.id }} = value
        end
      {% else %}
        property {{ var.id }} : {{kype}}

        # This is a private methods used for code generation
        private def _entitas_set_{{ var.id }}(value : {{kype}})
          @{{ var.id }} = value
        end
      {% end %}

      @@properties[:{{var.id}}] = {
        type:        {{kype}},
        key:         {{var.id.stringify}},
        has_default: {{kwargs[:default] ? true : false}},
        default:     {{kwargs[:default]}},
      }

    end

    # Class method to indicate if this component is unique
    def self.is_unique?
      false
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
