require "bencher"

macro start_bench(subject, block)
  Bencher.begin({{subject}}) do
    {{block.body}}
  end
end

macro group(name, tasks)
  Bencher.begin({{name}}) do
    {{tasks.body}}
  end
end

macro bench(name, before, task, after)
  {{before.body}}
  Bencher.begin({{name}}) do
    {{task.body}}
  end
  {{after.body}}
end

macro bench_n_times(name, n, before, task, after)
  {{before.body}}
  Bencher.begin({{name}}) do
    {{n}}.times do
      {{task.body}}
    end
  end
  {{after.body}}
end
