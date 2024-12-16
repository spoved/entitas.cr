require "../spec_helper"

private def new_contexts
  Contexts.new
end

private def new_standard_event_system
  contexts = new_contexts
  sys = ::Test4::EventSystem::StandardEvent::AnyListener.new(contexts)
  {sys, contexts}
end

private def new_flag_entity_event_system
  contexts = new_contexts
  sys = ::Test4::EventSystem::FlagEntityEvent::Listener.new(contexts)
  {sys, contexts}
end

private class RemoveEventTest
  include JSON::Serializable
  include ::StandardEvent::AnyListener
  include ::FlagEntityEvent::Listener

  property listener : Test4Entity
  property contexts : Contexts
  property? remove_comp_when_empty : Bool
  property value : String? = nil

  def initialize(@contexts, @remove_comp_when_empty)
    @listener = @contexts.test4.create_entity
    # logger.warn { "Listener: #{@listener}" }
    # logger.info { "add_any_standard_event_listener" }
    @listener.add_any_standard_event_listener(value: self)
    # logger.info { "add_flag_entity_event_listener" }
    @listener.add_flag_entity_event_listener(value: self)
  end

  def on_standard_event(entity, component : StandardEvent)
    # logger.warn { "on_standard_event" }
    @listener.remove_any_standard_event_listener(self, remove_comp_when_empty?)
    @value = component.value
  end

  def on_flag_entity_event(entity, component : FlagEntityEvent)
    # logger.warn { "on_flag_entity_event" }
    listener.remove_flag_entity_event_listener(self, remove_comp_when_empty?)
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

    it "can remove listener in callback in the middle" do
      event_sys, contexts = new_standard_event_system
      event_test_1 = RemoveEventTest.new(contexts, false)
      event_test_2 = RemoveEventTest.new(contexts, false)
      event_test_3 = RemoveEventTest.new(contexts, false)

      contexts.test4.create_entity.add_standard_event("Test")
      event_sys.execute

      event_test_1.value.should eq "Test"
      event_test_2.value.should eq "Test"
      event_test_3.value.should eq "Test"
    end

    it "can remove listener in callback and remove component" do
      event_sys, contexts = new_standard_event_system
      event_test = RemoveEventTest.new(contexts, true)
      contexts.test4.create_entity.add_standard_event("Test")
      event_sys.execute
      event_test.value.should eq "Test"
    end
  end

  describe "entity event" do
    it "can remove listener in callback" do
      event_sys, contexts = new_flag_entity_event_system
      event_test = RemoveEventTest.new(contexts, false)
      event_test.listener.flag_entity_event = true
      event_sys.execute
      event_test.value.should eq "true"
    end

    it "can remove listener in callback and remove component" do
      event_sys, contexts = new_flag_entity_event_system
      event_test = RemoveEventTest.new(contexts, true)
      event_test.listener.flag_entity_event = true
      event_sys.execute
      event_test.value.should eq "true"
    end
  end
end
