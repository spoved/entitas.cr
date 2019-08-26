module Entitas
  class Matcher
    def added : Entitas::Events::TriggerOn
      Entitas::Events::TriggerOn.new(self, Entitas::Events::GroupEvent::Added)
    end

    def removed : Entitas::Events::TriggerOn
      Entitas::Events::TriggerOn.new(self, Entitas::Events::GroupEvent::Removed)
    end

    def added_or_removed : Entitas::Events::TriggerOn
      Entitas::Events::TriggerOn.new(self, Entitas::Events::GroupEvent::AddedOrRemoved)
    end
  end
end
