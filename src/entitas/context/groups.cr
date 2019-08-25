require "../group"

module Entitas
  abstract class Context
    protected property groups : Hash(String, Entitas::Group) = Hash(String, Entitas::Group).new
    protected property groups_for_index : Array(Set(::Entitas::Group))
    private property group_events_buffer = Set(Tuple(Group, Entitas::Events::OnEntityAdded.class | Entitas::Events::OnEntityRemoved.class)).new

    # Returns a group for the specified matcher.
    # Calling context.GetGroup(matcher) with the same matcher will always
    # return the same instance of the group.
    def get_group(matcher : ::Entitas::Matcher) : ::Entitas::Group
      if self.groups[matcher.to_s]?
        self.groups[matcher.to_s]
      else
        group = Group.new(matcher)

        {% if !flag?(:disable_logging) %}logger.debug("created new group: #{group}", self){% end %}

        get_entities.each do |entity|
          group.handle_entity_silently(entity)
        end

        self.groups[matcher.to_s] = group

        matcher.indices.each do |i|
          groups_for_index[component_index_value(i)] << group
        end

        emit_event OnGroupCreated, self, group

        group
      end
    end

    def update_groups_component_added_or_removed(entity : ::Entitas::Entity, index : Int32, component : ::Entitas::Component?)
      {% if !flag?(:disable_logging) %}logger.debug("update_groups_component_added_or_removed : #{entity}", self.to_s){% end %}

      _groups = self.groups_for_index[index]?

      if !_groups.nil?
        group_events_buffer.clear

        _groups.each do |group|
          event_type = group.handle_entity(entity)
          next if event_type.nil?
          group_events_buffer.add({group, event_type})
        end

        group_events_buffer.each do |group, event_type|
          emit_group_event(group, event_type, entity, index, component)
        end
      end
    end

    private def emit_group_event(group, event_type, entity, index, component)
      {% if !flag?(:disable_logging) %}logger.debug("emit_group_event : #{event_type} : #{entity}", self.to_s){% end %}

      case event_type
      when ::Entitas::Events::OnEntityAdded.class
        group.receive_on_entity_added_event ::Entitas::Events::OnEntityAdded.new(group, entity, index, component)
      when ::Entitas::Events::OnEntityRemoved.class
        group.receive_on_entity_removed_event ::Entitas::Events::OnEntityRemoved.new(group, entity, index, component)
      else
        raise Error::UnknownEvent.new event_type.to_s
      end
    end

    def update_groups_component_replaced(entity : ::Entitas::Entity, index : Int32,
                                         prev_component : ::Entitas::Component?,
                                         new_component : ::Entitas::Component?)
      {% if !flag?(:disable_logging) %}logger.debug("update_groups_component_replaced : #{entity}", self.to_s){% end %}
      if groups_for_index[index]
        groups_for_index[index].each do |group|
          group.update_entity(entity, index, prev_component, new_component)
        end
      end
    end
  end
end
