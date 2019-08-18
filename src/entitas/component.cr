require "./macros/component"

module Entitas
  abstract class Component
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    # Component error class raised when an issue is encountered
    class Error < Exception
    end

    macro inherited

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

        \{% begin %}
        \{% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
        \{% for meth in @type.methods %}
          \{% if meth.name =~ /^_entitas_set_(.*)$/ %}
            \{% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
            \{% comp_methods[var_name] = meth %}
          \{% end %}
        \{% end %}

        \{% if comp_methods.empty? %}
          class ::Entitas::Entity
            def {{@type.name.id.underscore}}? : Bool
              has_component_{{@type.name.id.underscore}}?
            end
          end
        \{% end %}

        def initialize(
        \{% for var_name, meth in comp_methods %}
          \{% if meth.args[0].default_value %}
            @\{{var_name}} : \{{meth.args[0].restriction}}? = \{{meth.args[0].default_value}},
          \{% else %}
            @\{{var_name}} : \{{meth.args[0].restriction}}? = nil,
          \{% end %}
        \{% end %}
          )
        end


        # Will reset all instance variables to nil or their default value
        def reset
          \{% for var_name, meth in comp_methods %}
            \{% if meth.args[0].default_value %}
              @\{{var_name}} = \{{meth.args[0].default_value}}
            \{% else %}
              @\{{var_name}} = nil
            \{% end %}
          \{% end %}

          self
        end


        def init(**args)
          args.each do |k,v|
            case k
            \{% for var_name, meth in comp_methods %}
            when :\{{var_name}}
              @\{{var_name}} = v.as(\{{meth.args[0].restriction}})
            \{% end %}
            end
          end

          self
        end
        \{% end %}
      end


      # Add methods to Entitas::Entity
      ##

      class ::Entitas::Entity

        def replace_{{@type.name.id.underscore}}(component : {{@type.name.id}})
          self.replace_component(component)
        end

        def replace_component_{{@type.name.id.underscore}}(component : {{@type.name.id}})
          self.replace_{{@type.name.id.underscore}}(component)
        end

        def has_{{@type.name.id.underscore}}?
          self.has_component_{{@type.name.id.underscore}}?
        end

        def has_component_{{@type.name.id.underscore}}?
          self.has_component?(klass_to_index({{@type.name.id}}))
        end

        # Will return the component that is a `{{@type.name.id}}` or raise
        def {{@type.name.id.underscore}} : {{@type.id}}
          self.get_component_{{@type.name.id.underscore}}
        end

        def get_component_{{@type.name.id.underscore}} : {{@type.id}}
          self.get_component(klass_to_index({{@type.name.id}})).as({{@type.name.id}})
        end

        # Add a `{{@type.name.id}}` to the entity. Returns `self` to allow chainables
        # ```
        # entity.add_{{@type.name.id.underscore}}
        # ```
        def add_{{@type.name.id.underscore}}(**args) : ::Entitas::Entity
          self.add_component_{{@type.name.id.underscore}}(**args)
        end

        # Add a `{{@type.name.id}}` to the entity. Returns `self` to allow chainables
        # ```
        # entity.add_component_{{@type.name.id.underscore}}
        # ```
        def add_component_{{@type.name.id.underscore}}(**args) : ::Entitas::Entity
          component = self.create_component({{@type.name.id}}, **args)
          self.add_component(klass_to_index({{@type.name.id}}), component)
          self
        end

        # Delete `{{@type.name.id}}` from the entity. Returns `self` to allow chainables
        # ```
        # entity.del_{{@type.name.id.underscore}}
        # entity.{{@type.name.id.underscore}} # => nil
        # ```
        def del_{{@type.name.id.underscore}} : ::Entitas::Entity
          self.del_component_{{@type.name.id.underscore}}
          self
        end

        # Delete `{{@type.name.id}}` from the entity. Returns `self` to allow chainables
        # ```
        # entity.del_{{@type.name.id.underscore}}
        # entity.{{@type.name.id.underscore}} # => nil
        # ```
        def del_component_{{@type.name.id.underscore}} : ::Entitas::Entity
          self.remove_component(klass_to_index({{@type.name.id}}))
          self
        end

        # See `del_{{@type.name.id.underscore}}`
        def remove_{{@type.name.id.underscore}}
          self.del_{{@type.name.id.underscore}}
        end

        # See `del_component_{{@type.name.id.underscore}}`
        def remove_component_{{@type.name.id.underscore}}
          self.del_component_{{@type.name.id.underscore}}
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
      } of ::Entitas::Component::Index => ::Entitas::Component.class

      # A hash to map of class of `::Entitas::Component` to enum `Index`
      COMPONENT_TO_INDEX_MAP = {
        {% for sub_klass in @type.subclasses %}
          ::{{sub_klass.name.id}} => ::Entitas::Component::Index::{{sub_klass.name.id}},
        {% end %}
      } of ::Entitas::Component.class => ::Entitas::Component::Index

      TOTAL_COMPONENTS = {{i}}

      COMPONENT_NAMES = COMPONENT_TO_INDEX_MAP.keys.map &.to_s
      COMPONENT_KLASSES = COMPONENT_TO_INDEX_MAP.keys

      alias KlassList = Array(
        ::Entitas::Component.class
        {% if @type.subclasses.size == 1 %}
          )? | Array(
          {% for sub_klass in @type.subclasses %}
           ::{{sub_klass.name.id}}.class
          {% end %}
        {% end %}
      )?
      {% end %}
    end
  end
end
