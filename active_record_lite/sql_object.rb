require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    return @column_names if @column_names
    table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
       #{table_name}
    SQL
    @column_names = table[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=") { |var| attributes[col] = var }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name

  end

  def self.table_name
    @table_name || self.new.class.to_s.tableize

  end

  def self.all
   results = (DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
        SQL
        )
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL
    return nil if result.empty?
    self.new(result[0])
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      send("#{attr_name}=".to_sym, val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    colnames = self.class.columns[1..-1].join(',')
    question_marks = (["?"] * (self.attribute_values.length)).join(" , ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{colnames})
      VALUES
        ( #{question_marks} )
    SQL

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    colnames = self.class.columns.map{|col| "#{col} = ?"}.join(',')
    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{colnames}
      WHERE
        id = #{self.attributes[:id]}
      SQL

  end

  def save
    attributes[:id].nil? ? insert : update
  end
end
