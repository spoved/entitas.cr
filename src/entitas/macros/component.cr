module Entitas::IComponent
  # :nodoc:
  macro finalize_comp(name, index)
    {% if flag?(:entitas_debug_generator) %}{% puts "- finalize_comp for #{@type.id}" %}{% end %}

    class ::{{@type.id}}
      INDEX = Entitas::Component::Index::{{name.id}}
      INDEX_VALUE = {{index.id}}

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

      # :nodoc:
      # Method to initialize entity indexes for the component if needed
      # This really should not be used, but it is here for backwards compatibility
      def self.create_entity_index_for_ivars(ctx : T) forall T
        {% verbatim do %}
          {% for var in @type.instance_vars %}
            {% if var.annotation(::EntityIndex) %}
              {% index_name = (@type.id.gsub(/::/, "") + "EntityIndices#{var.name.camelcase.id}").underscore.upcase %}
              {% if flag?(:entitas_debug_generator) %}{% puts "  - create_entity_index for component: #{@type.id}, name: #{index_name}" %}{% end %}
              {% index = {
                   const:         index_name,
                   comp:          @type.id,
                   comp_meth:     @type.id.gsub(/.*::/, "").underscore.downcase,
                   prop:          var,
                   prop_meth:     var.name.underscore.downcase,
                   prop_type:     var.type.union_types.reject(&.==(Nil)).first,
                   context_name:  T.id.gsub(/Context/, ""),
                   contexts_meth: T.id.gsub(/Context/, "").underscore.downcase,
                 } %}

              ctx.add_entity_index(
                ::Entitas::EntityIndex({{index[:context_name].id}}Entity, {{index[:prop_type].id}}).new(
                  {{index[:const].stringify}},
                  ctx.get_group(
                    {{index[:context_name].id}}Matcher.{{index[:comp_meth].id}}
                  ),
                  ->(entity : {{index[:context_name].id}}Entity, component : Entitas::IComponent?) {
                    component.nil? ? entity.{{index[:comp_meth].id}}.{{index[:prop_meth].id}} : component.as({{index[:comp].id}}).{{index[:prop_meth].id}}
                  }
                )
              ) unless ctx.get_entity_index?({{index[:const].stringify}})
            {% end %} # end if var.annotation(::EntityIndex)
          {% end %} # end for var in @type.instance_vars
        {% end %} # end verbatim do
      end

      create_initializers
    end
  end

  # When the class is finished search the method names for each setter
  # and populate the initialize arguments.
  # :nodoc:
  macro create_initializers
    {% if @type.methods.find(&.name.==("init")) %}
      {% raise "#{@type} already has been initialized" %}
    {% end %}

    {% if flag?(:entitas_debug_generator) %}{% puts "  - create_initializers for #{@type.id}" %}{% end %}

    {% comp_variables = {} of StringLiteral => HashLiteral(SymbolLiteral, ArrayLiteral(TypeNode) | TypeNode) %}
    {% for meth in @type.methods %}
      {% if meth.annotation(::Component::Property) %}
        {% anno = meth.annotation(::Component::Property) %}
        {% var_name = anno.args.first %}
        {% comp_variables[var_name.id] = {
             :name    => var_name,
             :type    => anno.named_args[:type],
             :default => anno.named_args[:default],
             :index   => anno.named_args[:index],
             :not_nil => anno.named_args[:not_nil],
           } %}
      {% end %} # end if meth.annotation(::Component::Property)
    {% end %} # end for meth in @type.methods

    {% for meth in @type.methods %}
      {% if meth.name =~ /^_entitas_set_(.*)$/ %}
        {% var_name = meth.name.gsub(/^_entitas_set_/, "").id %}
        {% unless comp_variables[var_name] %}
          {% comp_variables[var_name] = {} of SymbolLiteral => ArrayLiteral(TypeNode) | TypeNode %}
        {% end %}
        {% comp_variables[var_name][:set_method] = meth %}
      {% end %}
    {% end %} # end for meth in @type.methods

    {% for var_name in comp_variables.keys %}
      {% for meth in @type.methods %}
        {% if meth.name == "_entitas_#{var_name.id}_method" %}
          {% comp_variables[var_name][:constructor] = meth %}
        {% end %}
      {% end %}
    {% end %} # end for var_name in comp_variables.keys

    def initialize(
      {% for var_name in comp_variables.keys %}
        {% meth = comp_variables[var_name][:set_method] %}
        {% if comp_variables[var_name][:constructor] %}
          {{var_name}} : {{meth.args[0].restriction}}? = nil,
        {% elsif meth.args[0].default_value %}
          @{{var_name}} : {{meth.args[0].restriction}}? = {{meth.args[0].default_value}},
        {% else %}
          @{{var_name}} : {{meth.args[0].restriction}}? = nil,
        {% end %}
      {% end %} # end for var_name in comp_variables.keys
      )

      {% for var_name in comp_variables.keys %}
        {% if comp_variables[var_name][:constructor] %}
          if {{var_name}}.nil?
            @{{var_name}} = {{comp_variables[var_name][:constructor].name}}
          else
            @{{var_name}} = {{var_name}}
          end
        {% end %} # end if comp_variables[var_name][:constructor]
      {% end %} # end for var_name in comp_variables.keys
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "name", {{@type.id.stringify}}
        json.field "unique", unique?
        json.field("data") do
          json.object do
            {% for var_name in comp_variables.keys %}
              json.field {{var_name.stringify}}, ({{var_name.id}}? ? {{var_name.id}} : nil)
            {% end %} # end for var_name in comp_variables.keys
          end
        end
      end
    end

    # Will reset all instance variables to nil or their default value
    def reset
      {% for var_name in comp_variables.keys %}
        {% meth = comp_variables[var_name][:set_method] %}

        {% if comp_variables[var_name][:constructor] %}
          @{{var_name}} = {{comp_variables[var_name][:constructor].name}}
        {% elsif meth.args[0].default_value %}
          @{{var_name}} = {{meth.args[0].default_value}}
        {% else %}
          @{{var_name}} = nil
        {% end %}
      {% end %}

      self
    end

    def init(**args)
      args.each do |k,v|
        case k
        {% for var_name in comp_variables.keys %}
        {% meth = comp_variables[var_name][:set_method] %}
        when :{{var_name}}
          {% if comp_variables[var_name][:constructor] %}
            @{{var_name}} = {{comp_variables[var_name][:constructor].name}}
          {% elsif meth.args[0].default_value %}
            @{{var_name}} = v.as({{meth.args[0].restriction}}) if v.is_a?({{meth.args[0].restriction}})
          {% else %}
            @{{var_name}} = v.as({{meth.args[0].restriction}}?) if v.is_a?({{meth.args[0].restriction}}?)
          {% end %}
        {% end %}
        else
          raise Exception.new("Unknown property #{k} for #{self.class}")
        end
      end

      self
    end
  end

  # :nodoc:
  macro setup_events
    {% if flag?(:entitas_debug_generator) %}{% puts "  - setup_events for #{@type.id}" %}{% end %}

    {% if @type.annotation(::Entitas::Event) %}
      {% for event in @type.annotations(::Entitas::Event) %}
        {% event_target = event.args[0] %}
        {% event_type = event.args[1] %}
        {% event_priority = event.named_args[:priority] %}
        {% contexts = [] of Path %}
        {% for anno in @type.annotations(::Context) %}{% anno.args.each { |a| contexts.push(a) } %}{% end %}
        {% if flag?(:entitas_debug_generator) %}{% puts "    - contexts: #{contexts}" %}{% end %}
        component_event({{contexts}}, {{@type.id}}, {{event_target.id}}, {{event_type.id}}, {{event_priority.id}})
        {% for context in contexts %}
        component_event_system({{context.id}}, {{@type.id}}, {{event_target.id}}, {{event_type.id}}, {{event_priority.id}})
        {% end %}
      {% end %}
    {% end %}
  end

  # :nodoc:
  macro setup_unique
    {% unique = @type.annotation(::Component::Unique) ? true : false %}

    {% if flag?(:entitas_debug_generator) %}{% puts "  - setup_unique for #{@type.id} : #{unique}" %}{% end %}

    # If the component has the unique annotation,
    #   set the class method to `true`
    # The framework will make sure that only one instance of a unique component can be present in your context
    {% if unique %}
      # Will return true if the class is a unique component for a context
      def unique? : Bool
        true
      end

      # :ditto:
      def self.unique? : Bool
        true
      end
    {% else %}
      # Will return true if the class is a unique component for a context
      def unique? : Bool
        false
      end

      # :ditto:
      def self.unique? : Bool
        false
      end
    {% end %}
  end

  # :nodoc:
  macro setup_base_comp
    {% if flag?(:entitas_debug_generator) %}{% puts "- setup_base_comp for #{@type.id}" %}{% end %}
    {% if !@type.ancestors.includes?(Entitas::IComponent) %}
      {% raise "#{@type.id} is not a Entitas::IComponent" %}
    {% end %}

    setup_unique
    setup_events
  end
end

class Entitas::Component
  macro create_index
    class ::Entitas::Component
      {% if flag?(:entitas_debug_generator) %}{% puts "### Creating component index" %}{% end %}

      {% components = [] of TypeNode %}
      {% comp_map = {} of TypeNode => HashLiteral(SymbolLiteral, HashLiteral(StringLiteral, ArrayLiteral(TypeNode)) | Bool) %}

      ### Gather all the components
      {% for obj in Object.all_subclasses.sort_by(&.name) %}
        {% if obj.annotation(::Context) %}
          {% components << obj %}
        {% end %}
      {% end %} # end for obj in Object.all_subclasses.sort_by(&.name)
      {% components = components.uniq %}

      ### Gather all the components and methods
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

      alias ComponentTypes = Union(Entitas::Component.class, {{comp_map.keys.map(&.name.+(".class")).splat}})

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
      {% for comp in comp_map.keys %}
        {{comp.id}}.finalize_comp({{comp.name.gsub(/.*::/, "").id}}, {{i}})
        {% i = i + 1 %}
      {% end %}
    end
  end
end
