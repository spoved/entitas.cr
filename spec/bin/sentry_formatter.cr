require "sentry"

format_sentry = Sentry::ProcessRunner.new(
  display_name: "crystal tool format",
  build_command: "/usr/local/bin/crystal",
  should_build: false,
  run_command: "/usr/local/bin/crystal",
  run_args: ["tool", "format"],
  files: ["./**/*.cr"]
)

format_sentry.run
