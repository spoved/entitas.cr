class Entitas::Context
  def create_collector(matcher : Entitas::Matcher) : Entitas::Collector
    self.create_collector Entitas::Events::TriggerOn.new(matcher, Entitas::Events::GroupEvent::Added)
  end

  def create_collector(*triggers : Entitas::Events::TriggerOn) : Entitas::Collector
    groups = Array(Entitas::Group).new
    group_events = Array(Entitas::Events::GroupEvent).new
    triggers.each do |t|
      groups << self.get_group(t.matcher)
      group_events << t.event
    end
    Entitas::Collector.new(groups, group_events)
  end
end
