# :nodoc:
macro create_instance_helpers(context)
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
