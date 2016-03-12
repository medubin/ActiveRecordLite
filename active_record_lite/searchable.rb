require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_string = params.to_a.map {|el| "#{el[0]} = '#{el[1]}'" }.join('AND ')
    results = (DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_string}
    SQL
    )
    self.parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
