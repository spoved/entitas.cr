require "../../src/entitas.cr"
require "./fixtures"
require "benchmark"

Spoved.logger.level = Logger::UNKNOWN

TASKS  = Array(Proc(Benchmark::BM::Job, Nil)).new
LOGGER = Logger.new(STDOUT)

def tasks
  TASKS
end

def n
  100_000
end

def logger
  LOGGER
end

macro start_bench(subject, block)
  func = ->(x : Benchmark::BM::Job) do
    puts "-- {{subject.id}} --"
    {{block.body}}
  end
  tasks << func
end

macro bench(name, before, task, after)
  func = ->(x : Benchmark::BM::Job) do
    begin
      {{before.body}}
      x.report({{name}}) do
        {{task.body}}
      end
      {{after.body}}
    end
    GC.collect
    nil
  end
  tasks << func
end

macro bench_n_times(name, before, task, after)
  func = ->(x : Benchmark::BM::Job) do
    begin
      {{before.body}}
      x.report({{name}}) do
        n.times do
          {{task.body}}
        end
      end
      {{after.body}}
    end
    GC.collect
    nil
  end
  tasks << func
end
