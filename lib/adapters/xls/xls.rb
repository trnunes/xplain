
load 'data_model.rb'
load 'xset.rb'
require 'roo'

#TODO Finish implementation and test 
class XlsSet < Xset
    
  def initialize(xls_path, relations = nil, id_column = 0, relations_row = 0)
    super(xls_path)    
    @xls = Roo::Excelx.new(xls_path)
    @id_column = id_column
    @relations_row = relations_row
    @elements = []
  end
  
  def elements
    each
  end
  
  def each(&block)
    relation_entities = []
    for i in (0..@xls.sheets.size - 1) do
      sheet_name = @xls.sheets[i]
      for row_index in (0..@xls.sheet(i).count - 1) do
        entity = Xplain::Entity.new(@xls.sheet(i).row(row_index)[@id_column])
        for cell_index in (0..@xls.sheet(i).row(row_index).size - 1) do
          if(row_index == @relations_row)
            relation_entities << Xplain::Entity.new(@xls.sheet(i).row(row_index)[cell_index])
          else
            if(cell_index != @id_column)
              cell_entity = Xplain::Entity.new(@xls.sheet(i).row(row_index)[cell_index])
              relation = Xplain::Relation.new(relation_entities[cell_index], Xplain::Relation.new(entity, cell_entity))
              if block_given?
                yield relation.second_item
                yield relation
              else
                @elements << relation
                @elements << relation.second_item
              end
            end
          end
        end
      end
    end
    @elements
  end
  
  def map(&block)
    result = []      
    if block_given?
      each{|pair| result.push(yield(pair))}
      result
    else
      each
    end
  end

  def select(&block)
    result = []      
    if block_given?
      each{|pair| result << pair if yield pair}
      result
    else
      each
    end
  end    
end  


# graph = RDF::Graph.load("http://dbpedia.org/resource/Elvis_Presley")
# set = Repository::RDFSet.new(graph)
# set.each{|pair| 
# elements = set.each
# 