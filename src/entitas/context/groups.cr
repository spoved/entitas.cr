module Entitas
  abstract class Context
    # Returns a group for the specified matcher.
    # Calling context.GetGroup(matcher) with the same matcher will always
    # return the same instance of the group.
    def get_group(matcher : ::Entitas::Matcher) : ::Entitas::Group
      if matcher.component_names.empty?
        matcher.component_names = info.component_names
      end

      if self.groups[matcher.to_s]?
        self.groups[matcher.to_s]
      else
        group = Group.new(matcher)

        logger.debug("created new group: #{group}", self)

        get_entities.each do |entity|
          group.handle_entity_silently(entity)
        end

        self.groups[matcher.to_s] = group

        matcher.indices.each do |i|
          groups_for_index[i.value] << group
        end

        emit_event OnGroupCreated, self, group

        group
      end
    end

    def update_groups_component_added_or_removed(entity : ::Entitas::Entity, index : Int32, component : ::Entitas::Component?)
      logger.debug "update_groups_component_added_or_removed : #{entity}", self.to_s

      event_list = Hash(Group, Entitas::Events::OnEntityAdded.class | Entitas::Events::OnEntityRemoved.class).new

      if groups_for_index[index]
        groups_for_index[index].each do |group|
          event = group.handle_entity(entity)

          next if event.nil?
          raise Error.new if event_list[group]?
          event_list[group] = event
        end
      end

      event_list.each do |group, event|
        case event
        when ::Entitas::Events::OnEntityAdded.class
          group.receive_on_entity_added_event ::Entitas::Events::OnEntityAdded.new(group, entity, index, component)
        when ::Entitas::Events::OnEntityRemoved.class
          group.receive_on_entity_removed_event ::Entitas::Events::OnEntityRemoved.new(group, entity, index, component)
        else
          raise Error::UnknownEvent.new event.to_s
        end
      end
    end

    def update_groups_component_replaced(entity : ::Entitas::Entity, index : Int32,
                                         prev_component : ::Entitas::Component?, new_component : ::Entitas::Component?)
      logger.debug "update_groups_component_replaced : #{entity}", self.to_s
      if groups_for_index[index]
        groups_for_index[index].each do |group|
          group.update_entity(entity, index, prev_component, new_component)
        end
      end
    end
  end
end
