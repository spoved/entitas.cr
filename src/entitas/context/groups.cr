module Entitas
  abstract class Context
    # Returns a group for the specified matcher.
    # Calling context.GetGroup(matcher) with the same matcher will always
    # return the same instance of the group.
    def get_group(matcher : ::Entitas::Matcher) : ::Entitas::Group
      if self.groups[matcher]?
        self.groups[matcher]
      else
        if matcher.component_names.empty?
          matcher.component_names = info.component_names
        end

        group = Group.new(matcher)

        get_entities.each do |entity|
          group.handle_entity_silently(entity)
        end

        self.groups[matcher] = group

        matcher.indices.each do |i|
          groups_for_index[i.value] << group
        end

        emit_event OnGroupCreated, self, group

        group
      end
    end

    def update_groups_component_added_or_removed(entity : ::Entitas::Entity, index : Int32, component : ::Entitas::Component?)
      if groups_for_index[index]
        groups_for_index[index].each do |group|
          event = group.handle_entity(entity)

          next if event.nil?

          case event
          when ::Entitas::Events::OnEntityAdded
            group.receive_on_entity_added_event ::Entitas::Events::OnEntityAdded.new(group, entity, index, component)
          when ::Entitas::Events::OnEntityRemoved
            group.receive_on_entity_removed_event ::Entitas::Events::OnEntityRemoved.new(group, entity, index, component)
          end
        end
      end
    end

    def update_groups_component_replaced(entity : ::Entitas::Entity, index : Int32,
                                         prev_component : ::Entitas::Component?, new_component : ::Entitas::Component?)
      if groups_for_index[index]
        groups_for_index[index].each do |group|
          group.update_entity(entity, index, prev_component, new_component)
        end
      end
    end
  end
end
