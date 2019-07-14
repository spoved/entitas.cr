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

      # TODO: Enable or remove
      # annotation ::Component::{{@type.name}}
      # end

      # If the component has the unique annotation,
      #   set the class method to `true`
      # The framework will make sure that only one instance of a unique component can be present in your context
      {% if @type.annotation(::Component::Unique) %}
        # Will return true if the class is a unique component for a context
        def is_unique?
          true
        end

        # Will return true if the class is a unique component for a context
        def self.is_unique?
          true
        end
      {% else %}
        # Will return true if the class is a unique component for a context
        def is_unique?
          false
        end

        # Will return true if the class is a unique component for a context
        def self.is_unique?
          false
        end
      {% end %}

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


      # Add methods to Entitas::Entity
      ##

      class ::Entitas::Entity

        def replace_{{@type.name.id.downcase}}(component : {{@type.name.id}})
          self.replace_component(component)
        end

        def has_{{@type.name.id.downcase}}?
          self.has_component_{{@type.name.id.downcase}}?
        end

        def has_component_{{@type.name.id.downcase}}?
          self.has_component?({{@type.name.id}}.index)
        end

        # Will return the component that is a `{{@type.name.id}}` or raise
        def {{@type.name.id.downcase}} : {{@type.id}}
          self.get_component_{{@type.name.id.downcase}}
        end

        def get_component_{{@type.name.id.downcase}} : {{@type.id}}
          self.get_component({{@type.name.id}}.index).as({{@type.name.id}})
        end

        # Add a `{{@type.name.id}}` to the entity
        # ```
        # entity.add_{{@type.name.id.downcase}}
        # ```
        def add_{{@type.name.id.downcase}}(**args)
          component = {{@type.name.id}}.new(**args)
          self.add_component({{@type.name.id}}.index, component)
        end


        # Delete *all* `{{@type.name.id}}` from the entity
        # ```
        # entity.del_{{@type.name.id.downcase}}
        # entity.{{@type.name.id.downcase}} # => nil
        # ```
        def del_{{@type.name.id.downcase}}
          self.remove_component({{@type.name.id}}.index)
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
    end

    # Will return true if the class is a unique component for a context
    def component_is_unique?
      self.class.is_unique?
    end

    # Component error class raised when an issue is encountered
    class Error < Exception
    end

    macro finished
      {% i = 0 %}

      enum Index
        {% for sub_klass in @type.subclasses %}
        {{sub_klass.name.id}} = {{i}}
        {% i = i + 1 %}
        {% end %}
      end


      # A hash to map of enum `Index` to class of `Component`
      INDEX_MAP = {
      {% for sub_klass in @type.subclasses %}
        ::Entitas::Component::Index::{{sub_klass.name.id}} => {{sub_klass.name.id}},
      {% end %}
      }

      # A hash to map of class of `Component` to enum `Index`
      COMPONENT_MAP = {
        {% for sub_klass in @type.subclasses %}
          {{sub_klass.name.id}} => ::Entitas::Component::Index::{{sub_klass.name.id}},
        {% end %}
      }

      # Make class functions on each sub-class to get the index easier
      {% for sub_klass in @type.subclasses %}

      class ::{{sub_klass.name.id}}

        # Returns the `::Entitas::Component::Index` corresponding to this class
        #
        # ```
        # entity.index # => ::Entitas::Component::Index::{{sub_klass.name.id}}
        # ```
        def self.index : ::Entitas::Component::Index
          ::Entitas::Component::Index::{{sub_klass.name.id}}
        end

        # Returns the `::Entitas::Component::Index::{{sub_klass.name.id}}#value` corresponding to this class
        #
        # ```
        # entity.index_value # => 1
        # ```
        def self.index_value : Int32
          self.index.value
        end
      end

      {% end %}

      # The total number of `::Entitas::Component` subclases
      TOTAL_COMPONENTS = {{i}}
    end
  end
end
