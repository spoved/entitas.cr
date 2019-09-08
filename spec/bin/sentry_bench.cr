require "sentry"

build_args = [
  "build",
  "spec/performance/bench.cr",
  "--release",
  "--error-trace",
  "-o", "bin/bench",
]

sentry = Sentry::ProcessRunner.new(
  display_name: "entitas performance tests",
  build_command: "/usr/local/bin/crystal",
  build_args: build_args,
  should_build: true,
  run_command: "bin/bench",
  files: ["./spec/performance/**/*.cr", "./src/**/*.cr"]
)

sentry.run
