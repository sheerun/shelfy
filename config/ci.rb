# bin/ci

def run_group(name, emoji: nil, default: true, &block)
  requested_groups = ARGV.map(&:downcase)
  # Match explicit group (e.g., 'e2e') or fall back to defaults
  should_run = true if requested_groups.include?(name.downcase)
  should_run = true if default && (requested_groups.empty? || requested_groups.include?("all"))

  return unless should_run

  if !name.empty?
    title = "#{emoji} Running #{name} test suite"
    puts "\n\033[1m#{title}\033[0m"
    puts "=" * (title.length + 2) + "\n\n"
  end

  start_time = Time.now
  success = block.call
  end_time = Time.now
  duration = (end_time - start_time).round(2)

  if !name.empty?
    if success
      puts "\n\033[1;32m✅ #{name} passed in #{duration}s\033[0m\n"
    else
      puts "\n\033[1;31m❌ #{name} failed in #{duration}s\033[0m\n"
      @suite_failed = true
    end
  end
end

suite_start_time = Time.now
@suite_failed = false

# SETUP: Required for standard Rails and E2E, excluding security/lint checks
def should_run_group(name, default: true)
  requested_groups = ARGV.map(&:downcase)
  return true if requested_groups.include?(name.downcase)
  return true if default && (requested_groups.empty? || requested_groups.include?("all"))
  false
end

setup_needed = should_run_group("Rails") || should_run_group("E2E", default: false)

run_group("", default: setup_needed) do
  system("bin/setup --skip-server > /dev/null")
end

run_group("Lint", emoji: "🎨") do
  system("bin/lint") &&
    system("bundle exec database_consistency")
end

run_group("Security", emoji: "🔒") do
  system("bin/bundler-audit check") &&
    system("bin/brakeman --quiet --no-pager --exit-on-warn")
end

run_group("RSpec", emoji: "🚂") do
  system("bin/rspec #{ARGV.drop(1).join(" ")}")
end

suite_end_time = Time.now
suite_duration = (suite_end_time - suite_start_time).round(2)

if @suite_failed
  puts "\n\033[1;31m❌ Whole test suite failed in #{suite_duration}s\033[0m\n\n"
  exit 1
else
  puts "\n\033[1;32m✅ Whole test suite passed in #{suite_duration}s\033[0m\n\n"
end
