module Entitas
  class Context
    class Error < Exception
      class Info < Error
        getter context : Entitas::Context
        getter context_info : Entitas::Context::Info

        def initialize(@context, @context_info)
        end

        def to_s
          "Invalid ContextInfo for '#{context}'!\nExpected " \
          "#{context.total_components} component_name(s) but got " \
          "#{context_info.component_names.size}:#{context_info.component_names.join("\n")}"
        end
      end

      class StillHasRetainedEntities < Error
        getter context : Context
        getter retained_entities : Array(Entity)

        def initialize(@context, @retained_entities)
        end
      end

      class UnknownEvent < Error; end
    end
  end
end
