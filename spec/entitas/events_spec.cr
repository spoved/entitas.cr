require "../spec_helper"

private def new_contexts
  Contexts.new
end

private def new_standard_event_system
  contexts = new_contexts
  sys = StandardEvent::AnyListener::EventSystem::Test4.new(contexts)
  {sys, contexts}
end

private class RemoveEventTest
  include ::StandardEvent::AnyListener
  include ::FlagEntityEvent::Listener

  property listener : Test4Entity
  property contexts : Contexts
  property remove_comp_when_empty : Bool
  property value : String? = nil

  def initialize(@contexts, @remove_comp_when_empty)
    @listener = @contexts.test4.create_entity
    @listener.add_any_standard_event_listener(self)
    @listener.add_flag_entity_event_listener(self)
  end

  def on_standard_event(entity, component : StandardEvent)
    puts "on_standard_eventon_standard_eventon_standard_eventon_standard_eventon_standard_event"
    @listener.remove_any_standard_event_listener(self, remove_comp_when_empty)
    @value = component.value
  end

  def on_flag_entity_event(entity, component : FlagEntityEvent)
    puts "on_flag_entity_eventon_flag_entity_eventon_flag_entity_event"
    listener.remove_flag_entity_event_listener(self, remove_comp_when_empty)
    @value = "true"
  end
end

describe "Events" do
  describe "event" do
    it "can remove listener in callback" do
      event_sys, contexts = new_standard_event_system
      event_test = RemoveEventTest.new(contexts, false)
      contexts.test4.create_entity.add_standard_event("Test")
      event_sys.execute
      event_test.value.should eq "Test"
    end
  end
end
