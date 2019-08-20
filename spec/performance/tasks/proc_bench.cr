module ::Entitas::Events
  create_event EventOne, {name: String}
end

alias EventOneHook = Proc(::Entitas::Events::EventOne, Nil)

EVENT_ONE_HOOK_CACHE = ->(event : ::Entitas::Events::EventOne) {
  nil
}

class TestProcs
  accept_events EventOne
  emits_events EventOne

  @data = Array(EventOneHook | Nil).new(1, nil)
  @data_empty = Array(EventOneHook | Nil).new
  @event_one_instance_var : EventOneHook = ->(event : ::Entitas::Events::EventOne) {
    nil
  }

  def event_one_instance_var : EventOneHook
    @event_one_instance_var
  end

  def event_one_instance_method(&block : EventOneHook)
    @data[0] = block
  end

  def event_one_instance_method_append(&block : EventOneHook)
    @data_empty << block
  end

  def data
    @data
  end

  def clear_data_empty
    @data_empty = Array(EventOneHook | Nil).new
  end
end

# puts "Trying to allocate some mem"
# begin
#   Array(EventOneHook | Nil).new(100_000, ->(event : ::Entitas::Events::EventOne) {
#     nil
#   })
# rescue exception
# end

start_bench "Proc", ->do
  group "Assignment", ->do
    bench "control", ->{
      data = Array(EventOneHook | Nil).new(1, nil)
    }, ->{
      data[0] = nil
    }, ->{}, true

    bench "using const", ->{
      data = Array(EventOneHook | Nil).new(1, nil)
    }, ->{
      data[0] = EVENT_ONE_HOOK_CACHE
    }, ->{}, true

    bench "using dynamic", ->{
      data = Array(EventOneHook | Nil).new(1, nil)
    }, ->{
      data[0] = ->(event : ::Entitas::Events::EventOne) {
        nil
      }
    }, ->{}, true

    bench "using instance var", ->{
      test = TestProcs.new
      data = Array(EventOneHook | Nil).new(1, nil)
    }, ->{
      data[0] = test.event_one_instance_var
    }, ->{}, true

    bench "using method", ->{
      test = TestProcs.new
    }, ->{
      test.event_one_instance_method do |_|
        nil
      end
    }, ->{}, true
  end

  group "Append", ->do
    bench "control", ->{}, ->{
      data = Array(EventOneHook | Nil).new
      data << nil
    }, ->{}, true

    bench "using const", ->{}, ->{
      data = Array(EventOneHook | Nil).new
      data << EVENT_ONE_HOOK_CACHE
    }, ->{}, true

    bench "using dynamic", ->{}, ->{
      data = Array(EventOneHook | Nil).new
      data << ->(event : ::Entitas::Events::EventOne) {
        nil
      }
    }, ->{}, true

    bench "using instance var", ->{
      test = TestProcs.new
    }, ->{
      data = Array(EventOneHook | Nil).new
      data << test.event_one_instance_var
    }, ->{}, true

    bench "using method", ->{
      test = TestProcs.new
    }, ->{
      test.clear_data_empty
      test.event_one_instance_method_append do |_|
        nil
      end
    }, ->{}, true
  end
end
