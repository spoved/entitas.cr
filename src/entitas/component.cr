require "./macros/component"

module Entitas
  abstract class Component
    spoved_logger

    # Component error class raised when an issue is encountered
    class Error < Exception
    end

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
          @\{{var_name}} : \{{meth.args[0].restriction}}? = \{{meth.args[0].default_value}},
        \{% else %}
          @\{{var_name}} : \{{meth.args[0].restriction}}? = nil,
        \{% end %}
        \{% end %}
        \{% end %}
          )
        end


        # Will reset all instance variables to nil or their default value
        def init
          \{% for meth in @type.methods %}
          \{% if meth.name =~ /^_entitas_set_(.*)$/ %}
          \{% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
          \{% if meth.args[0].default_value %}
            @\{{var_name}} = \{{meth.args[0].default_value}}
          \{% else %}
            @\{{var_name}} = nil
          \{% end %}
          \{% end %}
          \{% end %}

          self
        end
      end


      # Add methods to Entitas::Entity
      ##

      class ::Entitas::Entity

        def replace_{{@type.name.id.downcase}}(component : {{@type.name.id}})
          self.replace_component(component)
        end

        def replace_component_{{@type.name.id.downcase}}(component : {{@type.name.id}})
          self.replace_{{@type.name.id.downcase}}(component)
        end

        def has_{{@type.name.id.downcase}}?
          self.has_component_{{@type.name.id.downcase}}?
        end

        def has_component_{{@type.name.id.downcase}}?
          self.has_component?(klass_to_index({{@type.name.id}}))
        end

        # Will return the component that is a `{{@type.name.id}}` or raise
        def {{@type.name.id.downcase}} : {{@type.id}}
          self.get_component_{{@type.name.id.downcase}}
        end

        def get_component_{{@type.name.id.downcase}} : {{@type.id}}
          self.get_component(klass_to_index({{@type.name.id}})).as({{@type.name.id}})
        end

        # Add a `{{@type.name.id}}` to the entity. Returns `self` to allow chainables
        # ```
        # entity.add_{{@type.name.id.downcase}}
        # ```
        def add_{{@type.name.id.downcase}}(**args) : ::Entitas::Entity
          self.add_component_{{@type.name.id.downcase}}(**args)
        end

        # Add a `{{@type.name.id}}` to the entity. Returns `self` to allow chainables
        # ```
        # entity.add_component_{{@type.name.id.downcase}}
        # ```
        def add_component_{{@type.name.id.downcase}}(**args) : ::Entitas::Entity
          component = {{@type.name.id}}.new(**args)
          self.add_component(klass_to_index({{@type.name.id}}), component)
          self
        end

        # Delete `{{@type.name.id}}` from the entity. Returns `self` to allow chainables
        # ```
        # entity.del_{{@type.name.id.downcase}}
        # entity.{{@type.name.id.downcase}} # => nil
        # ```
        def del_{{@type.name.id.downcase}} : ::Entitas::Entity
          self.del_component_{{@type.name.id.downcase}}
          self
        end

        # Delete `{{@type.name.id}}` from the entity. Returns `self` to allow chainables
        # ```
        # entity.del_{{@type.name.id.downcase}}
        # entity.{{@type.name.id.downcase}} # => nil
        # ```
        def del_component_{{@type.name.id.downcase}} : ::Entitas::Entity
          self.remove_component(klass_to_index({{@type.name.id}}))
          self
        end

        # See `del_{{@type.name.id.downcase}}`
        def remove_{{@type.name.id.downcase}}
          self.del_{{@type.name.id.downcase}}
        end

        # See `del_component_{{@type.name.id.downcase}}`
        def remove_component_{{@type.name.id.downcase}}
          self.del_component_{{@type.name.id.downcase}}
        end
      end
    end

    # Will return true if the class is a unique component for a context
    def component_is_unique?
      self.class.is_unique?
    end

    macro finished
      {% begin %}
      {% i = 0 %}

      enum Index
        {% for sub_klass in @type.subclasses %}
        {{sub_klass.name.id}} = {{i}}
        {% i = i + 1 %}
        {% end %}
      end

      # A hash to map of enum `Index` to subclass of `::Entitas::Component`
      INDEX_TO_COMPONENT_MAP = {
      {% for sub_klass in @type.subclasses %}
        ::Entitas::Component::Index::{{sub_klass.name.id}} => ::{{sub_klass.name.id}},
      {% end %}
      }

      # A hash to map of class of `::Entitas::Component` to enum `Index`
      COMPONENT_TO_INDEX_MAP = {
        {% for sub_klass in @type.subclasses %}
          ::{{sub_klass.name.id}} => ::Entitas::Component::Index::{{sub_klass.name.id}},
        {% end %}
      }

      TOTAL_COMPONENTS = {{i}}

      COMPONENT_NAMES = COMPONENT_TO_INDEX_MAP.keys.map &.to_s
      COMPONENT_KLASSES = COMPONENT_TO_INDEX_MAP.keys
      {% end %}
    end
  end
end
