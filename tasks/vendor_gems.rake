# This is an optional pre-tar-task, so we only want to present it if we're
# using it
if @build.pre_tar_task == "package:vendor_gems"
  namespace :package do
    desc "vendor gems required by project"
    task :vendor_gems do
      check_tool("bundle")
      require 'bundler'

      class UI
        LEVELS = %w(silent error warn confirm info debug)

        def warn(message, newline = nil)
          puts message
        end

        def debug(message, newline = nil)
          puts message
        end

        def trace(message, newline = nil)
          puts message
        end

        def error(message, newline = nil)
          puts message
        end

        def info(message, newline = nil)
          puts message
        end

        def confirm(message, newline = nil)
        end

        def debug?
          false
        end

        def ask(message)
        end

        def quiet?
          false
        end

        def level=(level)
          raise ArgumentError unless LEVELS.include?(level.to_s)
          @level = level
        end

        def level(name = nil)
          name ? LEVELS.index(name) <= LEVELS.index(@level) : @level
        end

        def silence
          old_level, @level = @level, "silent"
          yield
        ensure
          @level = old_level
        end

      end

      class RGProxy < ::Gem::SilentUI
        def initialize(ui)
          @ui = ui
          super()
        end

        def say(message)
          if message =~ /native extensions/
            @ui.info "with native extensions "
          else
            @ui.debug(message)
          end
        end
      end


      Bundler.settings[:cache_all] = true

      Bundler.ui = UI.new()
      Bundler.rubygems.ui = ::RGProxy.new(Bundler.ui)
      Bundler.ui.level = "info"

      definition = Bundler.definition
      definition.validate_ruby!
      definition.resolve_remotely!

      mkdir_p Bundler.app_cache

      definition.specs.each do |spec|
        Bundler::Fetcher.fetch(spec) if spec.source.is_a?(Bundler::Source::Rubygems)
        spec.source.cache(spec) unless spec.name == "bundler"
      end

    end
  end
end
