require "../../src/entitas.cr"
require "./fixtures"
require "benchmark"

Spoved.logger.level = Logger::UNKNOWN
LOGGER = Logger.new(STDOUT)

alias BenchCall = Proc(Benchmark::IPS::Job, Nil)

TASKS_BUFFER = Array(BenchCall).new
TASKS        = Hash(String, Array(BenchCall)).new

def logger
  LOGGER
end

def run
  TASKS.each do |name, tasks|
    puts "-- #{name} --"

    Benchmark.ips do |x|
      tasks.each &.call(x)
    end
  end
end

macro start_bench(subject, block)

  {{block.body}}

  TASKS[{{subject.id.stringify}}] = TASKS_BUFFER.dup

  TASKS_BUFFER.clear
end

macro bench(name, before, task, after)
  func = ->(x : Benchmark::IPS::Job) do
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
  TASKS_BUFFER << func
end

macro bench_n_times(name, n, before, task, after)
  func = ->(x : Benchmark::IPS::Job) do
    begin
      {{before.body}}
      x.report({{name}}) do
        {{n}}.times do
          {{task.body}}
        end
      end
      {{after.body}}
    end
    GC.collect
    nil
  end
  TASKS_BUFFER << func
end
