module Audit
  module Request
    class << self
      def controller_info=(value)
        store[:controller_info] = value
      end

      def controller_info
        store[:controller_info]
      end

      def whodunnit=(value)
        store[:whodunnit] = value
      end

      def whodunnit
        who = store[:whodunnit]
        who.respond_to?(:call) ? who.call : who
      end

      def enabled=(value)
        store[:enabled] = value
      end

      def enabled?
        !!store[:enabled]
      end

      def with(options)
        return unless block_given?
        before = store.dup
        options.each { |k, v| store[k] = v }
        yield
      ensure
        store.replace(before)
      end

      private

      def store
        Thread.current[:audit_request] ||= { enabled: true }
      end
    end
  end
end
