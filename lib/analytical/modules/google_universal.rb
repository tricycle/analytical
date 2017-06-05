module Analytical
  module Modules
    class GoogleUniversal
      include Analytical::Modules::Base

      def initialize(options = {})
        super
        @tracking_command_location = :head_append
      end

      def init_javascript(location)
        init_location(location) do
          js = <<-HTML
          <!-- Analytical Init: Google Universal -->

          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

          ga('create', '#{options[:key]}', 'auto', #{tracker_init_options});
          #{"ga('require', 'linkid', 'linkid.js');" if options[:enhanced_link_attribution]}
          #{"ga('require', 'ecommerce', 'ecommerce.js');" if options[:ecommerce]}
          #{"ga('require', 'displayfeatures');" if options[:displayfeatures]}
          #{identify_commands.join("\n")}
          #{dimension_commands.join("\n")}
          ga('send', 'pageview');
          </script>
          HTML
          js
        end
        clear_commands
      end

      def event(name, *args)
        data = args.first || {}
        data = data[:value] if data.is_a?(Hash)
        ga 'send', 'event', 'Event', name, data.to_s
      end

      def identify(id, *_args)
        ga 'set', 'userId', id
      end

      def dimension(index, value)
        ga 'set', "dimension#{index}", value
      end

      private

      def ga(*array)
        args = array.reject(&:blank?).join("', '")
        "ga('#{args}');"
      end

      def clear_commands
        @command_store.commands = @command_store.commands.delete_if do |command|
          identifier = command[0]
          identifier == :identify || identifier == :dimension
        end
      end

      def tracker_init_options
        init_options = {
          allowLinker: options.fetch(:allow_linker, false),
          siteSpeedSampleRate: options.fetch(:sample_rate, 0)
        }
        init_options.merge(cookieDomain: options[:domain]) if options.key?(:domain)
        init_options.to_json
      end

      def identify_commands
        @command_store
          .commands
          .select { |command| command[0] == :identify }
          .map { |command| identify(*command[1..-1]) }
      end

      def dimension_commands
        @command_store
          .commands
          .select { |command| command[0] == :dimension }
          .map { |command| dimension(*command[1..-1]) }
      end
    end
  end
end
