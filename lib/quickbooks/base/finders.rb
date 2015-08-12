module Quickbooks
  class Base
    module Finders

      def find_by_id(id, model = nil)
        if model
          new_service = service_for(model)
          new_service.fetch_by_id(id)
        else
          @service.fetch_by_id(id)
        end
      end

      def qbuilder
        Quickbooks::Util::QueryBuilder.new
      end

      def sql_builder(where, options = {})
        options[:entity] ||= entity
        options[:select] ||= '*'
        "SELECT #{options[:select]} FROM #{qbo_case(options[:entity])} WHERE #{where}"
      end

      def display_name_sql(display_name, options = {})
        options[:select] ||= 'Id, DisplayName'
        where = qbuilder.clause("DisplayName", "=", display_name)
        sql_builder(where, options)
      end

      def find_by_display_name(display_name, options = {})
        sql = display_name_sql(display_name, options)
        service = determine_service(options[:entity])
        service.query(sql)
      end
    end
  end
end

