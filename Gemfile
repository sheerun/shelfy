source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache and Active Job
gem "solid_cache"
gem "solid_queue"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Linting and formatting [https://github.com/standardrb/standard]
  gem "standard", require: false

  # Git hooks [https://github.com/evilmartians/lefthook]
  gem "lefthook", require: false

  # RSpec for testing [https://rspec.info/]
  gem "rspec-rails", "~> 8.0"

  # API documentation with OpenAPI/Swagger [https://github.com/rswag/rswag]
  gem "rswag-specs"

  # Database consistency checks [https://github.com/djezzzl/database_consistency]
  gem "database_consistency", require: false
end
