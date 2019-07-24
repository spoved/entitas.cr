module Entitas
  abstract class Context
    protected property groups_for_index : Array(Group) = Array(Group).new

    def update_groups_component_added_or_removed(entity : Entity, index : Int32, component : Component)
    end

    def update_groups_component_replaced(entity : Entity, index : Int32,
                                         prev_component : Component, new_component : Component)
    end
  end
end
