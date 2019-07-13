require "./component"
require "./entity/*"

module Entitas
  class Entity
    class Error < Exception
    end

    include Entitas::Entity::Index

    @components : Array(Entitas::Component) = Array(Entitas::Component).new

    # Will add the `Entitas::Component` at the provided index
    def add_component(index : Int32, component : Entitas::Component)
      check_unique_component(component) if component.component_is_unique?

      if @components[index]
        raise Entitas::Entity::Error.new("Component already set at index: #{index}")
      end

      @components[index] = component
    end

    # Will return the `Entitas::Component` at the provided index
    def get_component(index : Int32) : Entitas::Component
      @components[index]
    end

    def has_component?(index : Int32) : Bool
      @components[index]?
    end

    def has_components?(indices : Array(Int32)) : Bool
      indices.each do |index|
        return false unless @components[index]?
      end
      true
    end

    def has_any_component?(indices : Array(Int32)) : Bool
      indices.each do |index|
        return true if @components[index]?
      end
      false
    end

    # Will delete the component at the provided index
    def del_component(index : Int32)
      @components.delete_at(index)
    end

    # Checks `self` for a component with the same class and will raise a `Entitas::Entity::Error` if found
    private def check_unique_component(component : Entitas::Component)
      @components.each do |comp|
        if comp.class == component.class
          raise Entitas::Entity::Error.new("Component #{component.class} is unique")
        end
      end
    end
  end
end
