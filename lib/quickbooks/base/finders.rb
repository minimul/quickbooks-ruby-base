module Quickbooks
  class Base
    module Finders

      def find_by_id(id)
        @service.fetch_by_id(id)
      end

      def qbuilder
        Quickbooks::Util::QueryBuilder.new
      end

      def sql_builder(where, options = {})
        options[:entity] ||= @entity
        options[:select] ||= '*'
        "SELECT #{options[:select]} FROM #{options[:entity]} WHERE #{where}"
      end

      def display_name_sql(display_name, options = {})
        options[:select] ||= 'Id, DisplayName'
        where = qbuilder.clause("DisplayName", "=", display_name)
        sql_builder(where, options)
      end

      def find_by_display_name(display_name, options = {})
        sql = display_name_sql(display_name, options)
        @service.query(sql)
      end
    end
  end
end

