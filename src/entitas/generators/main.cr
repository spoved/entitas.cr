require "./contexts"
require "./context"
require "./component"

macro finished
  Entitas::Component.check_components
  Entitas::Component.create_index

  {% verbatim do %}
    {% begin %}


      {% context_map = {} of TypeNode => ArrayLiteral(TypeNode) %}
      {% events_map = {} of TypeNode => ArrayLiteral(TypeNode) %}
      {% comp_map = {} of TypeNode => HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

      ### Gather all the contexts
      {% for obj in Object.all_subclasses.sort_by(&.name) %}
        {% if obj.annotation(::Context) %}
          {% contexts = obj.annotations(::Context).uniq %}
          {% if flag?(:entitas_debug_generator) %}{% puts "Found component #{obj.id} with contexts: #{contexts}" %}{% end %}

          {% for context in contexts %}
            {% for anno in context.args %}
              {% context_map[anno] = [] of ArrayLiteral(TypeNode) if context_map[anno].is_a?(Nil) %}
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
          {% events_map[obj] = [] of ArrayLiteral(Annotation) if events_map[obj].is_a?(Nil) %}
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

          {% component_name = comp.name.gsub(/.*::/, "") %}
          {% component_meth_name = component_name.underscore %}
          {% comp_map[comp] = {
               :name        => component_name,
               :methods     => comp_methods,
               :index_alias => comp.id.gsub(/::/, "").underscore.upcase,
               :meth_name   => component_meth_name.id,
               :contexts    => [] of ArrayLiteral(TypeNode),
               :flag        => comp_methods.empty? ? true : false,
               :unique      => comp.annotation(::Component::Unique) ? true : false,
             } %}
        {% end %}
      {% end %} # end for anno, components in context_map

      # Create entity, matcher, and context
      {% for context_name, components in context_map %}
        {% components = components.uniq %}

        # `Entitas::Entity` for the `{{context_name.id}}Context`
        class ::{{context_name.id}}Entity < Entitas::Entity
          {% for comp in components %}

            # Append contexts to comp_map
            {% comp_map[comp][:contexts] = [] of ArrayLiteral(TypeNode) if comp_map[comp][:contexts].is_a?(Nil) %}
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

      # Define `Entitas::Contexts` methods for accessing sub contexts
      Entitas::Contexts.generate_sub_context_methods

      # Create any entity indexes
      #############################################
      {% entity_indices = [] of HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

      {% for comp, comp_methods in comp_map %}
        {% for meth in comp.methods %}
          {% if meth.annotation(::EntityIndex) %}
            {% anno = meth.annotation(::EntityIndex) %}
            {% index_name = (comp.id.gsub(/::/, "") + "EntityIndices#{meth.name.camelcase.id}").underscore.upcase %}
            {% for context in comp_methods[:contexts] %}
              {%
                entity_indices.push({
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

      class ::Entitas::Matcher
        gen_functions
      end

      class ::Entitas::Contexts
        # Will be called after initialization to intitialze each `EntityIndex` for
        # all of the contexts.
        @[::Entitas::PostConstructor]
        def initialize_entity_indices
          {% if flag?(:entitas_debug_generator) %}
            {% puts "## Initialize entity indices" %}
            {% puts " - found #{entity_indices.size} indices" %}
          {% end %}

          {% for comp, comp_methods in comp_map %}
            {% for context in comp_methods[:contexts] %}
              {{comp}}.create_entity_index_for_ivars(self.{{context.id.underscore.downcase}})
            {% end %} # end for context in comp_methods[:contexts]
          {% end %} # end for comp, comp_methods in comp_map

          {% for index in entity_indices %}
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
          {% end %} # end for index in entity_indices
        end

        {% for index in entity_indices %}
          {% if index[:comp].constants.find(&.stringify.==("#{index[:prop].id.titleize}Index")) %}
            {% raise "#{index[:comp].id}::#{index[:prop].id.titleize}Index has already been generated!" %}
          {% else %}
            module ::{{index[:comp].id}}::{{index[:prop].id.titleize}}Index(T)
              abstract def get_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value : {{index[:prop_type].id}}) : Array(T)
              abstract def get_entity_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value : {{index[:prop_type].id}}) : T?
            end
          {% end %}

          module Extensions::{{index[:context_name].id}}Indexes
            include ::{{index[:comp].id}}::{{index[:prop].id.titleize}}Index({{index[:context_name].id}}Entity)

            def get_{{index[:contexts_meth].id}}_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(context : {{index[:context_name].id}}Context, value : {{index[:prop_type].id}})
              context.get_entity_index(::Contexts::{{index[:const].id}})
                .as(::Entitas::EntityIndex({{index[:context_name].id}}Entity, {{index[:prop_type].id}}))
                .get_entities(value)
            end

            def get_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value : {{index[:prop_type].id}}) : Array({{index[:context_name].id}}Entity)
              get_{{index[:contexts_meth].id}}_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(self, value)
            end

            def get_entity_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value : {{index[:prop_type].id}}) : {{index[:context_name].id}}Entity?
              get_entities_with_{{ index[:comp_meth].id }}_{{ index[:prop].id }}(value).first?
            end
          end
        {% end %} # end for index in entity_indices
      end

      {% for index in entity_indices %}
        class ::{{index[:context_name].id}}Context < Entitas::Context(::{{index[:context_name].id}}Entity)
          include ::Entitas::Contexts::Extensions::{{index[:context_name].id}}Indexes
        end
      {% end %} # end for index in entity_indices

    {% end %} # begin
  {% end %} # end verbatim do

  generate_event_systems
end

require "./*"
