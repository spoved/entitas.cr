private macro create_instance_helpers(context)
  # Will return the `Entitas::Component::Index` for the provided index
  def component_index(index) : Entitas::Component::Index
    {{context.id}}.component_index(index)
  end

  def component_index_value(index) : Int32
    {{context.id}}.component_index_value(index)
  end

  def component_index_class(index) : Entitas::Component::ComponentTypes
    {{context.id}}.component_index_class(index)
  end
end

macro finished
  {% verbatim do %}
    {% begin %}
      {% context_map = {} of TypeNode => ArrayLiteral(TypeNode) %}
      {% events_map = {} of TypeNode => ArrayLiteral(TypeNode) %}
      {% comp_map = {} of TypeNode => HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

      {% for obj in Object.all_subclasses.sort_by(&.name) %}
        ### Gather all the contexts
        {% if obj.annotation(::Context) %}
          {% contexts = obj.annotations(::Context) %}
          {% for context in contexts %}
            {% for anno in context.args %}
              {% context_map[anno] = [] of ArrayLiteral(TypeNode) if context_map[anno].nil? %}
              {% array = context_map[anno] %}
              {% if array == nil %}
                {% context_map[anno] = [obj] %}
              {% else %}
                {% context_map[anno] = array + [obj] %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}

        ### Gather all the events
        {% if obj.annotation(::Entitas::Event) %}
          {% events_map[obj] = [] of ArrayLiteral(Annotation) if events_map[obj].nil? %}
          {% events_map[obj] = obj.annotations(::Entitas::Event) %}
        {% end %} # end if obj.annotation(::Entitas::Event)
      {% end %} # end for obj in Object.all_subclasses.sort_by(&.name)

      ### Gather all the components and methods
      {% for anno, components in context_map %}
        {% components = components.uniq %}
        {% for comp in components %}
          {% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
          {% for meth in comp.methods %}
            {% if meth.name =~ /^_entitas_set_(.*)$/ %}
              {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
              {% comp_methods[var_name] = meth %}
            {% end %}
          {% end %}
          {% comp_map[comp] = comp_methods %}
        {% end %}
      {% end %} # end for anno, components in context_map

      class ::Entitas::Component
        alias ComponentTypes = Union(Entitas::Component.class, {{*comp_map.keys.map(&.name.+(".class"))}})

        {% if comp_map.empty? %}
          enum Index
            None
          end
        {% else %}
          enum Index
            {% begin %}
              {% i = 0 %}
              {% for comp in comp_map.keys %}
                {{comp.name.gsub(/.*::/, "").id}} = {{i}}
                {% i = i + 1 %}
              {% end %}
            {% end %}
          end
        {% end %}

        # A hash to map of enum `Index` to class of `Component`
        INDEX_TO_COMPONENT_MAP = {
          {% for comp in comp_map.keys %}
            Index::{{comp.name.gsub(/.*::/, "").id}} => ::{{comp.id}},
          {% end %}
        } of Index => Entitas::Component::ComponentTypes

        # A hash to map of class of `Component` to enum `Index`
        COMPONENT_TO_INDEX_MAP = {
          {% for comp in comp_map.keys %}
            ::{{comp.id}} => Index::{{comp.name.gsub(/.*::/, "").id}},
          {% end %}
        } of Entitas::Component::ComponentTypes => Index

        COMPONENT_NAMES = COMPONENT_TO_INDEX_MAP.keys.map &.to_s
        COMPONENT_KLASSES = [
          {% for comp in comp_map.keys %}
            ::{{comp.id}},
          {% end %}
        ] of Entitas::Component::ComponentTypes

        # The total number of componets
        TOTAL_COMPONENTS = {{comp_map.size}}

        # The total amount of components an entity can possibly have.
        def total_components : Int32
          TOTAL_COMPONENTS
        end

        def self.total_components : Int32
          TOTAL_COMPONENTS
        end

        {% i = 0 %}
        {% for comp, comp_methods in comp_map %}
          {% component_name = comp.name.gsub(/.*::/, "") %}

          class ::{{comp.id}}

            INDEX = Entitas::Component::Index::{{component_name.id}}
            INDEX_VALUE = {{i}}

            def self.index_val : Int32
              INDEX_VALUE
            end

            def index_val : Int32
              INDEX_VALUE
            end

            def self.index : Entitas::Component::Index
              INDEX
            end

            def index : Entitas::Component::Index
              INDEX
            end

          end
        {% end %}

      end

      ### Cycle through components and inject `Entitas::IComponent` and make helper modules
      {% for comp, comp_methods in comp_map %}

        {% component_name = comp.name.gsub(/.*::/, "") %}
        {% component_meth_name = component_name.underscore %}

        ### Check to see if the component is a subklass of ::Entitas::Component

        {% if !comp.ancestors.includes?(Entitas::IComponent) %}
          class ::{{comp.id}}
            include Entitas::IComponent

            def is_unique? : Bool
              {% if comp.annotation(::Component::Unique) %}
              true
              {% else %}
              false
              {% end %}
            end
          end
        {% end %} # end if !comp.ancestors.includes?(Entitas::IComponent)

        ### Create a Helper module for each component

        module ::{{comp.id}}::Helper
          {% is_flag = false %}

          {% comp_methods = {} of StringLiteral => ArrayLiteral(TypeNode) %}
          {% for meth in comp.methods %}
            {% if meth.name =~ /^_entitas_set_(.*)$/ %}
              {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
              {% comp_methods[var_name] = meth %}
            {% end %}
          {% end %}

          {% is_flag = comp_methods.empty? ? true : false %}
          {% is_unique = comp.annotation(::Component::Unique) ? true : false %}

          {% comp_map[comp] = {
               :methods     => comp_methods,
               :flag        => is_flag,
               :unique      => is_unique,
               :index_alias => comp.id.gsub(/::/, "").underscore.upcase,
               :meth_name   => component_meth_name.id,
             } %}

          {% if is_flag %}
            def {{component_meth_name}}?
              self.has_component?(self.component_index_value({{component_name.id}}))
            end

            def {{component_meth_name}}=(value : Bool)
              if value
                self.add_component_{{component_meth_name}}
              else
                self.del_component_{{component_meth_name}} if self.has_{{component_meth_name}}?
              end
            end
          {% end %}



          {% if comp_map[comp][:methods].size == 1 %}
            {% n = comp_map[comp][:methods].keys.first %}
            # Will replace the current component with the new one
            # generated from the provided arguments
            #
            # ```
            # entity.replace_{{component_meth_name}}(value: 1)
            # entity.get_{{component_meth_name}} # => (new_comp)
            # ```
            #
            # or
            #
            # ```
            # entity.replace_{{component_meth_name}}(1)
            # entity.get_{{component_meth_name}} # => (new_comp)
            # ```
            def replace_{{component_meth_name}}({{n.id}} : {{comp_map[comp][:methods][n].args[0].restriction.id}})
              component = self.create_component(::{{comp.id}}, {{n.id}}: {{n.id}})
              self.replace_component(self.component_index_value(::{{comp.id}}), component)
            end
          {% elsif comp_map[comp][:methods].size > 1 %}
            # Will replace the current component with the new one
            # generated from the provided arguments
            #
            # ```
            # entity.replace_{{component_meth_name}}
            # entity.get_{{component_meth_name}} # => (new_comp)
            # ```
            def replace_{{component_meth_name}}(**args)
              component = self.create_component(::{{comp.id}}, **args)
              self.replace_component(self.component_index_value(::{{comp.id}}), component)
            end
          {% else %}
            # Will replace the current component with the new one
            # generated from the provided arguments
            #
            # ```
            # entity.replace_{{component_meth_name}}
            # entity.get_{{component_meth_name}} # => (new_comp)
            # ```
            def replace_{{component_meth_name}}
              component = self.create_component(::{{comp.id}})
              self.replace_component(self.component_index_value(::{{comp.id}}), component)
            end
          {% end %}

          # Will replace the current component with the new one provided
          #
          # ```
          # entity.replace_component_{{component_meth_name}}(new_comp)
          # entity.get_{{component_meth_name}} # => (new_comp)
          # ```
          def replace_{{component_meth_name}}(component : ::{{comp.id}})
            self.replace_component_{{component_meth_name}}(component)
          end

          # Append. Alias for `replace_{{component_meth_name}}`
          def replace_component_{{component_meth_name}}(component : ::{{comp.id}})
            self.replace_component(self.component_index_value(::{{comp.id}}), component)
          end

          # Will replace the current component with the new one
          # generated from the provided arguments
          #
          # ```
          # entity.replace_{{component_meth_name}}
          # entity.get_{{component_meth_name}} # => (new_comp)
          # ```
          def replace_component_{{component_meth_name}}(**args)
            component = self.create_component(::{{comp.id}}, **args)
            self.replace_component(self.component_index_value(::{{comp.id}}), component)
          end

          # Will return true if the entity has an component `{{comp.id}}` or false if it does not
          def has_{{component_meth_name}}? : Bool
            self.has_component_{{component_meth_name}}?
          end

          # Alias. See `#has_{{component_meth_name}}?`
          def {{component_meth_name}}? : Bool
            self.has_component_{{component_meth_name}}?
          end

          # Will return true if the entity has an component `{{comp.id}}` or false if it does not
          def has_component_{{component_meth_name}}? : Bool
            self.has_component?(self.component_index_value(::{{comp.id}}))
          end

          # Will return the component that is a `{{comp.id}}` or raise
          def {{component_meth_name}} : ::{{comp.id}}
            self.get_component_{{component_meth_name}}
          end

          # Will return the component that is a `{{comp.id}}` or raise
          def get_component_{{component_meth_name}} : ::{{comp.id}}
            self.get_component(self.component_index_value(::{{comp.id}})).as(::{{comp.id}})
          end

          {% if comp_map[comp][:methods].size == 1 %}
            {% n = comp_map[comp][:methods].keys.first %}
            {% meth_n = comp_map[comp][:methods][n].args[0] %}
            # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.add_{{component_meth_name}}(1)
            # ```
            def add_{{component_meth_name}}(
                {{n.id}} : {{meth_n.restriction.id}} {% if meth_n.default_value %}= {{meth_n.default_value}}{% end %}
              ) : Entitas::Entity
              {% if flag?(:entitas_enable_logging) %}Log.debug { "add_{{component_meth_name}} - {{n.id}}: #{{{n.id}}}" }{% end %}
              self.add_component_{{component_meth_name}}({{n.id}}: {{n.id}})
            end
          {% elsif comp_map[comp][:methods].size > 1 %}
            # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.add_{{component_meth_name}}
            # ```
            def add_{{component_meth_name}}(**args) : Entitas::Entity
              self.add_component_{{component_meth_name}}(**args)
            end
          {% else %}
            # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
            #
            # ```
            # entity.add_{{component_meth_name}}
            # ```
            def add_{{component_meth_name}} : Entitas::Entity
              self.add_component_{{component_meth_name}}
            end
          {% end %}

          # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
          #
          # ```
          # entity.add_component_{{component_meth_name}}
          # ```
          def add_component_{{component_meth_name}} : Entitas::Entity
            component = self.create_component(::{{comp.id}})
            self.add_component(self.component_index_value(::{{comp.id}}), component)
            self
          end

          # Add a `{{comp.id}}` to the entity. Returns `self` to allow chainables
          #
          # ```
          # entity.add_component_{{component_meth_name}}
          # ```
          def add_component_{{component_meth_name}}(**args) : Entitas::Entity
            component = self.create_component(::{{comp.id}}, **args)
            self.add_component(self.component_index_value(::{{comp.id}}), component)
            self
          end

          # Delete `{{comp.id}}` from the entity. Returns `self` to allow chainables
          #
          # ```
          # entity.del_{{component_meth_name}}
          # entity.{{component_meth_name}} # => nil
          # ```
          def del_{{component_meth_name}} : Entitas::Entity
            self.del_component_{{component_meth_name}}
            self
          end

          # Delete `{{comp.id}}` from the entity. Returns `self` to allow chainables
          #
          # ```
          # entity.del_{{component_meth_name}}
          # entity.{{component_meth_name}} # => nil
          # ```
          def del_component_{{component_meth_name}} : Entitas::Entity
            self.remove_component(self.component_index_value(::{{comp.id}}))
            self
          end

          # Append. Alias for `del_{{component_meth_name}}`
          def remove_{{component_meth_name}}
            self.del_{{component_meth_name}}
          end

          # Append. Alias for `del_component_{{component_meth_name}}`
          def remove_component_{{component_meth_name}}
            self.del_component_{{component_meth_name}}
          end
        end

      {% end %} # end for comp, comp_methods in comp_map

      # Create entity, matcher, and context

      {% for context_name, components in context_map %}
        {% components = components.uniq %}

        # `Entitas::Entity` for the `{{context_name.id}}Context`
        class ::{{context_name.id}}Entity < Entitas::Entity
          {% for comp in components %}

            # Append contexts to comp_map
            {% comp_map[comp][:contexts] = [] of ArrayLiteral(TypeNode) if comp_map[comp][:contexts].nil? %}
            {% array = comp_map[comp][:contexts] %}
            {% if array == nil %}
              {% comp_map[comp][:contexts] = [context_name] %}
            {% else %}
              {% comp_map[comp][:contexts] = array + [context_name] %}
            {% end %}


            include ::{{comp.name.id}}::Helper
          {% end %} # end for comp in components

          create_instance_helpers(::{{context_name.id}}Context)
        end

        class ::{{context_name.id}}Matcher < Entitas::Matcher
          {% for comp in components %}
          class_getter {{comp.name.gsub(/.*::/, "").underscore.id}} = Entitas::Matcher.all_of({{comp.id}})
          {% end %} # end for comp in components
        end

        # Create a sub class of `Entitas::Context` with the corresponding
        # name and provided components
        #############################################


        # Sub context {{context_name.id}}
        class ::{{context_name.id}}Context < Entitas::Context(::{{context_name.id}}Entity)
         protected def component_names
            COMPONENT_NAMES
          end

          protected def name
            CONTEXT_NAME
          end

          def to_json(json : JSON::Builder)
            json.object do
              json.field "name", CONTEXT_NAME
              json.field "size", self.size
              json.field "entities", get_entities
              json.field "components", COMPONENT_NAMES
              json.field "creation_index", creation_index
              json.field "info", context_info
              json.field "reusable_entities", reusable_entities.size
              json.field "retained_entities", retained_entities.size

              json.field "component_pools" do
                json.object do
                  component_pools.each_with_index do |pool, i|
                    json.field i, pool.size
                  end
                end
              end

              json.field "groups_for_index", groups_for_index
            end
          end

          enum Index
            {% begin %}
              {% i = 0 %}
              {% for comp in components %}
                {{comp.name.gsub(/.*::/, "").id}} = {{i}}
                {% i = i + 1 %}
              {% end %}
            {% end %}
          end

          CONTEXT_NAME = "{{context_name.id}}Context"
          ENTITY_KLASS = ::{{context_name.id}}Entity

          # A hash to map of enum `Index` to class of `Component`
          INDEX_TO_COMPONENT_MAP = {
            {% for comp in components %}
              Index::{{comp.name.gsub(/.*::/, "").id}} => ::{{comp.id}},
            {% end %}
          } of Index => Entitas::Component::ComponentTypes

          # A hash to map of class of `Component` to enum `Index`
          COMPONENT_TO_INDEX_MAP = {
            {% for comp in components %}
              ::{{comp.id}} => Index::{{comp.name.gsub(/.*::/, "").id}},
            {% end %}
          } of Entitas::Component::ComponentTypes => Index

          # Unique components
          UNIQUE_COMPONENTS = [
          {% for comp in components %}
            {% if comp_map[comp][:unique] %}
              ::{{comp.name.id}},
            {% end %}
          {% end %}
          ] of Entitas::Component::ComponentTypes

          # The total number of `Entitas::Component` subclases in this context
          TOTAL_COMPONENTS = {{components.size}}

          COMPONENT_NAMES = [
            {% for comp in components %}
              {{comp.id.stringify}},
            {% end %}
          ]
          COMPONENT_KLASSES = [
            {% for comp in components %}
              ::{{comp.id}},
            {% end %}
          ] of Entitas::Component::ComponentTypes

          # The total amount of components an entity can possibly have.
          def total_components : Int32
            TOTAL_COMPONENTS
          end

          # :ditto:
          def self.total_components : Int32
            TOTAL_COMPONENTS
          end

          private def create_default_context_info : Entitas::Context::Info
            {% if flag?(:entitas_enable_logging) %}
              Log.debug { "Creating default context" }
            {% end %}

            @component_names_cache.clear
            @component_names_cache = COMPONENT_NAMES

            Entitas::Context::Info.new(
              CONTEXT_NAME,
              component_names_cache,
              COMPONENT_KLASSES
            )
          end

          # Default `#entity_factory` for `{{context_name.id}}Context`
          #
          # ```
          # ctx = {{context_name.id}}Context.new
          # ctx.entity_factory # => {{context_name.id}}Entity
          # ```
          def entity_factory : ::{{context_name.id}}Entity
            ::{{context_name.id}}Entity.new(
              creation_index,
              total_components,
              component_pools,
              context_info,
            )
          end

          # Will return true if the context contains the component,
          # false if it does not.
          def self.has_component?(index) : Bool
            case index
            {% i = 0 %}
            {% for comp in components %}
            when {{i}}, ::{{comp.id}}.class, Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}
              true
            {% i = i + 1 %}
            {% end %}
            else
              false
            end
          end

          # Will return the `Entitas::Matcher` class for the context
          def self.matcher : ::{{context_name.id}}Matcher
            ::{{context_name.id}}Matcher.new(Entitas::Component::COMPONENT_NAMES)
          end

          # Will return the `Entitas::Component::Index` for the provided index
          def self.component_index(index) : Entitas::Component::Index
            case index
            {% i = 0 %}
            {% for comp in components %}
            when {{i}}, ::{{comp.id}}.class
              Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}
            {% i = i + 1 %}
            {% end %}
            else
              raise Entitas::Entity::Error::DoesNotHaveComponent.new
            end
          end

          def self.component_index_value(index) : Int32
            case index
            {% i = 0 %}
            {% for comp in components %}
            when Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}, ::{{comp.id}}.class
              {{i}}
            {% i = i + 1 %}
            {% end %}
            else
              {% if flag?(:entitas_enable_logging) %}Log.error { "Unable to find index: #{index} value: #{index.value}" }{% end %}

              raise Entitas::Entity::Error::DoesNotHaveComponent.new
            end
          end

          def self.component_index_class(index) : Entitas::Component::ComponentTypes
            case index
            {% i = 0 %}
            {% for comp in components %}
            when Entitas::Component::Index::{{comp.name.gsub(/.*::/, "").id}}, {{i}}
              ::{{comp.id}}
            {% i = i + 1 %}
            {% end %}
            else
              raise Entitas::Entity::Error::DoesNotHaveComponent.new
            end
          end

          create_instance_helpers(::{{context_name.id}}Context)

          # For each unique component create functions to add, edit and remove
          # entities at the context level
          {% for comp in components %}
            {% if comp_map[comp][:unique] %}
              {% comp_name = comp_map[comp][:meth_name] %}

              def {{comp_name.id}}_entity? : ::{{context_name.id}}Entity?
                self.get_group(::{{context_name.id}}Matcher.{{comp_name.id}}).get_single_entity
              end

              def {{comp_name.id}}_entity : ::{{context_name.id}}Entity
                entity = {{comp_name.id}}_entity?
                raise Entitas::Entity::Error::DoesNotHaveComponent.new if entity.nil?
                entity.as(::{{context_name.id}}Entity)
              end

              def {{comp_name.id}} : {{comp.id}}
                entity = {{comp_name.id}}_entity?
                raise Error.new "No {{comp.id}} has been set for #{self}" if entity.nil?
                entity.{{comp_name.id}}
              end

              {% if comp_map[comp][:flag] %}

                def {{comp_name.id}}=(value : Bool)
                  if value == true && {{comp_name.id}}_entity?.nil?
                    self.create_entity.add_{{comp_name.id}}
                  elsif value == true && !{{comp_name.id}}_entity?.nil?
                    # Do nothing
                  elsif value == false && {{comp_name.id}}_entity?.nil?
                    # DO nothing
                  elsif value == false && !{{comp_name.id}}_entity?.nil?
                    {{comp_name.id}}_entity.del_{{comp_name.id}}
                  end
                end

                # Will check to see if there is a `{{context_name.id}}Entity` with
                # a `{{comp.id}}` component
                def {{comp_name.id}}? : Bool
                  !{{comp_name.id}}_entity?.nil?
                end

              {% else %}

              # Will check to see if there is a `{{context_name.id}}Entity` with
              # a `{{comp.id}}` component
              def has_{{comp_name.id}}? : Bool
                !{{comp_name.id}}_entity?.nil?
              end

              # Alias. See `#has_{{comp_name.id}}?`
              def {{comp_name.id}}? : Bool
                !{{comp_name.id}}_entity?.nil?
              end

              # Will create a new `{{context_name.id}}Entity` and set the `{{comp.id}}` to the
              # provided value. If an entity already exists with the unique component,
              # a `Error` will be raised. The created `{{context_name.id}}Entity` will be returned
              #
              # ```
              # context.set_{{comp_name.id}}({{comp.id}}.new) # => {{context_name.id}}Entity
              # ```
              def set_{{comp_name.id}}(value : {{comp.id}}) : {{context_name.id}}Entity
                if has_{{comp_name.id}}?
                  raise Error.new "Could not set {{comp.id}}!\n" \
                    "#{self} already has an entity with {{comp.id}}!" \
                    "You should check if the context already has a " \
                    "{{comp_name.id}} Entity before setting " \
                    "it or use context.replace_{{comp_name.id}}."
                end
                entity = self.create_entity
                entity.add_component(value)
                entity
              end

              def {{comp_name.id}}=(value : {{comp.id}}) : Entitas::Entity
                set_{{comp_name.id}}(value)
              end

              # Replaces the `{{comp.id}}` on an existing `{{context_name.id}}Entity`.
              # If no existing `{{context_name.id}}Entity` with a `{{comp.id}}` exists,
              # one will be created. Will return the `{{context_name.id}}Entity` with the
              # replaced component.
              def replace_{{comp_name.id}}(value : {{comp.id}}) : {{context_name.id}}Entity
                entity = self.{{comp_name.id}}_entity?
                if entity.nil?
                  entity = set_{{comp_name.id}}(value)
                else
                  entity.replace_component(value)
                end
                entity
              end

              # Replaces the `{{comp.id}}` on an existing `{{context_name.id}}Entity`.
              # If no existing `{{context_name.id}}Entity` with a `{{comp.id}}` exists,
              # one will be created. Will return the `{{context_name.id}}Entity` with the
              # replaced component.
              def replace_{{comp_name.id}}(**args) : {{context_name.id}}Entity
                entity = self.{{comp_name.id}}_entity?
                if entity.nil?
                  entity = self.create_entity.add_component_{{comp_name.id}}(**args)
                else
                  entity.replace_component_{{comp_name.id}}(**args)
                end
                entity
              end

              {% end %}

            {% end %}
          {% end %}
        end
      {% end %} # end for context_name, components in context_map

      # Create any entity indexes
      #############################################
      {% entity_indicies = [] of HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

      {% for comp, comp_methods in comp_map %}
        {% component_name = comp.name.gsub(/.*::/, "") %}

        {% for meth in comp.methods %}
          {% if meth.annotation(::EntityIndex) %}
            {% anno = meth.annotation(::EntityIndex) %}
            {% index_name = (comp.id.gsub(/::/, "") + "EntityIndices#{meth.name.camelcase.id}").underscore.upcase %}
            {% for context in comp_methods[:contexts] %}
              {%
                entity_indicies.push({
                  const:         index_name,
                  comp:          comp,
                  comp_meth:     comp_methods[:meth_name],
                  prop:          anno[:var],
                  prop_meth:     meth.name,
                  prop_type:     anno[:type],
                  context_name:  context,
                  contexts_meth: "#{context}".underscore.downcase,
                })
              %}
            {% end %} # end for context in comp_methods[:contexts]
          {% end %} # end if meth.annotation(::EntityIndex)
        {% end %} # end for meth in comp.methods
      {% end %} # end for comp, comp_methods in comp_map

      class ::Entitas::Contexts

        # Will be called after initialization to intitialze each `EntityIndex` for
        # all of the contexts.
        @[::Entitas::PostConstructor]
        def initialize_entity_indices
          {% for index in entity_indicies %}
            self.{{index[:contexts_meth].id}}.add_entity_index(
              ::Entitas::EntityIndex({{index[:context_name].id}}Entity, {{index[:prop_type].id}}).new(
                ::Entitas::Contexts::{{index[:const].id}},
                {{index[:contexts_meth].id}}.get_group(
                  {{index[:context_name].id}}Matcher.{{index[:comp_meth].id}}
                ),
                ->(entity : {{index[:context_name].id}}Entity, component : Entitas::IComponent?) {
                  component.nil? ? entity.{{index[:comp_meth].id}}.{{index[:prop_meth].id}} : component.as({{index[:comp].id}}).{{index[:prop_meth].id}}
                }
              )
            )
          {% end %} # end for index in entity_indicies
        end

        {% for index in entity_indicies %}
          module {{index[:context_name].id}}Extensions
            def get_{{index[:contexts_meth].id}}_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(context : {{index[:context_name].id}}Context, value : {{index[:prop_type].id}})
              context.get_entity_index(::Contexts::{{index[:const].id}})
                .as(::Entitas::EntityIndex({{index[:context_name].id}}Entity, {{index[:prop_type].id}}))
                .get_entities(value)
            end

            def get_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value : {{index[:prop_type].id}}) : Array({{index[:context_name].id}}Entity)
              get_{{index[:contexts_meth].id}}_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(self, value)
            end

            def get_entity_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value : {{index[:prop_type].id}}) : {{index[:context_name].id}}Entity?
              get_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value).first
            end
          end
        {% end %} # end for index in entity_indicies
      end

      {% for index in entity_indicies %}
        class ::{{index[:context_name].id}}Context < Entitas::Context(::{{index[:context_name].id}}Entity)
          include ::Entitas::Contexts::{{index[:context_name].id}}Extensions
        end
      {% end %} # end for index in entity_indicies

    {% end %} # begin
  {% end %} # end verbatim do
end
