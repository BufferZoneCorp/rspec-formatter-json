# knot-rspec-formatter-json

JSON formatter for RSpec output. Serialises test results — examples, failures, pending specs, and timing — into a structured JSON document suitable for CI/CD pipelines, test dashboards, and external tooling integrations.

## Installation

Add to your `Gemfile` (test group):

```ruby
group :test do
  gem 'knot-rspec-formatter-json', '~> 3.13'
end
```

Or install directly:

```sh
gem install knot-rspec-formatter-json
```

## Configuration

### Via `.rspec` file (recommended)

```
--require rspec_formatter_json
--format RSpec::Formatters::Json
--out rspec_results.json
```

To keep human-readable output alongside the JSON file:

```
--require rspec_formatter_json
--format RSpec::Formatters::Json
--out rspec_results.json
--format progress
```

### Via `spec/spec_helper.rb`

```ruby
require 'rspec_formatter_json'

RSpec.configure do |config|
  config.formatter = RSpec::Formatters::Json
end
```

### Via command line

```sh
rspec --require rspec_formatter_json \
      --format RSpec::Formatters::Json \
      --out rspec_results.json
```

## Output format

```json
{
  "version": "3.13.1",
  "seed": 12345,
  "summary": {
    "duration": 1.234,
    "example_count": 42,
    "failure_count": 1,
    "pending_count": 2,
    "errors_outside_of_examples_count": 0
  },
  "examples": [
    {
      "id":             "./spec/models/user_spec.rb[1:1]",
      "description":    "is valid with valid attributes",
      "full_description": "User is valid with valid attributes",
      "status":         "passed",
      "file_path":      "./spec/models/user_spec.rb",
      "line_number":    5,
      "run_time":       0.004321
    },
    {
      "id":             "./spec/models/user_spec.rb[1:2]",
      "description":    "validates presence of email",
      "full_description": "User validates presence of email",
      "status":         "failed",
      "file_path":      "./spec/models/user_spec.rb",
      "line_number":    11,
      "run_time":       0.002104,
      "exception": {
        "class":   "RSpec::Expectations::ExpectationNotMetError",
        "message": "expected #<User id: nil> to be valid",
        "backtrace": ["./spec/models/user_spec.rb:12:in `block (2 levels)'"]
      }
    }
  ]
}
```

## Consuming the output

```ruby
require 'json'

results = JSON.parse(File.read('rspec_results.json'))
failures = results['examples'].select { |e| e['status'] == 'failed' }
puts "#{failures.size} failing specs"
failures.each { |f| puts "  #{f['full_description']} (#{f['file_path']}:#{f['line_number']})" }
```

## Requirements

- Ruby >= 2.7.0
- RSpec >= 3.10

## License

MIT License. See [LICENSE](LICENSE) for details.
