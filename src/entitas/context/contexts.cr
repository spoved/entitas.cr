require "./context"

module Entitas
  class Contexts
    def self.shared_instance
      @@_shared_instance ||= Entitas::Contexts.new
    end

    def all_contexts
      @contexts ||= Array(Entitas::Context).new
    end

    def reset
      all_contexts.each do |context|
        context.reset
      end
    end
  end
end
