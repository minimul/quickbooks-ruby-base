module Quickbooks
  class Base
    module Configuration
      def configure
        yield self
      end

      def oauth_consumer=(var)
        @oauth_consumer = var
      end

      def oauth_consumer
        @oauth_consumer ||= $qb_oauth_consumer
      end

      %w(token secret company_id).each do |type|
        class_eval <<-eos
          def persistent_#{type}=(location)
            @persistent_#{type} = location
          end

          def persistent_#{type}
            @persistent_#{type} ||= 'settings.qb_#{type}'
          end
        eos
      end
    end
  end
end
