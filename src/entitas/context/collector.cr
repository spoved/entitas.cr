class Entitas::Context(TEntity)
  def create_collector(matcher : Entitas::Matcher) : Entitas::Collector(TEntity)
    self.create_collector Entitas::Events::TriggerOn.new(matcher, Entitas::Events::GroupEvent::Added)
  end

  def create_collector(*triggers : Entitas::Events::TriggerOn) : Entitas::Collector(TEntity)
    groups = Array(Entitas::Group(TEntity)).new
    group_events = Array(Entitas::Events::GroupEvent).new
    triggers.each do |t|
      groups << self.get_group(t.matcher)
      group_events << t.event
    end
    Entitas::Collector(TEntity).new(groups, group_events)
  end
end
