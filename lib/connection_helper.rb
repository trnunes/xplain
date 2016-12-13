module ConnectionHelper
  def self.load_jdbc_libs(sgdb)
    case sgdb
    when 'mysql'
      require './lib/mysql-connector-java-5.1.18-bin'
      require 'jdbc/mysql'    
    when 'postgresql'
      require './lib/postgresql-9.4.1208.jre6'
      require 'jdbc/postgres'
      Jdbc::Postgres.load_driver
    else
      
    end
  end

  def self.url_for(sgdb, dbname, user=nil, password=nil, port=nil)  
    url = "jdbc:#{sgdb}://localhost"
    url += ":#{port}"               unless port.nil?
    url += "/#{dbname}"             unless dbname.nil?
    url += "?user=#{user}"          unless user.nil?
    url += "?password=#{password}"  unless password.nil?
    url
  end

  def self.connect_to(url)
    load_jdbc_libs(url.split(":")[1])
    java::sql::DriverManager.getConnection(url)
  end

  def self.query(connection, query, &block)  
    stmt = connection.create_statement
    rs = stmt.execute_query(query)

    if block_given?
      while rs.next
        row = []
        for index in(1..rs.getMetaData.getColumnCount)
          row << rs.getObject(index)           
        end
        yield(row)
      end
    end
    rs
  end
end