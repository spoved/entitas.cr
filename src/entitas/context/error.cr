require "./info"

module Entitas
  class Context
    class Error < Exception
    end

    class InfoException < Error
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
  end
end
