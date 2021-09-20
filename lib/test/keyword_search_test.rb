require './test/xplain_unit_test'

class Xplain::KeywordSearchTest < XplainUnitTest
  module Xplain::Visualization
    current_profile.label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "http://www.w3.org/1999/02/22-rdf-syntax-ns#label"
  end
  
  def test_dbpedia_lookup
    
    expected_result = [
      Xplain::Entity.new("http://dbpedia.org/resource/Brazil"),
      Xplain::Entity.new("http://dbpedia.org/resource/Municipalities_of_Brazil"),
      Xplain::Entity.new("http://dbpedia.org/resource/Brazil_national_football_team"),
      Xplain::Entity.new("http://dbpedia.org/resource/Northeast_Region,_Brazil"),
      Xplain::Entity.new("http://dbpedia.org/resource/Time_in_Brazil"),
      Xplain::Entity.new("http://dbpedia.org/resource/Southeast_Region,_Brazil"),
      Xplain::Entity.new("http://dbpedia.org/resource/South_Region,_Brazil"),
      Xplain::Entity.new("http://dbpedia.org/resource/Brazil_national_under-20_football_team"),
      Xplain::Entity.new("http://dbpedia.org/resource/Central-West_Region,_Brazil"),
      Xplain::Entity.new("http://dbpedia.org/resource/North_Region,_Brazil"),

    ]
    result_set = @server.match_all("Brazil")
    puts(result_set.inspect)
    assert_equal (expected_result & result_set).sort, expected_result.sort
  end

  def test_empty_keyword_phrase_nil
    
    
    assert_raise MissingArgumentException do
      Xplain::KeywordSearch.new.get_results()
    end    
    
  end

  def test_empty_keyword_phrase
    
    assert_raise MissingArgumentException do
      Xplain::KeywordSearch.new.get_results(server: @papers_server, keyword:  '')
    end    
  end
  
  def test_keyword_search_no_whole_dataset
    expected_results = Set.new(create_nodes [ Xplain::Entity.new(server: @papers_server, id: '_:paper1')])
    
    result_set =  Xplain::KeywordSearch.new.get_results(server: @papers_server, keyword:  'paper1_keyword')
    
    
    assert_same_items_set expected_results, result_set    
  end
  
  def test_keyword_search_restricted_scope
    restriction_input = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: '_:paper1'), Xplain::Entity.new(server: @papers_server, id: '_:p2'), 
      Xplain::Entity.new(server: @papers_server, id: '_:p3'), Xplain::Entity.new(server: @papers_server, id: '_:p4')
    ]
    input = Xplain::ResultSet.new(nodes:  restriction_input)
    
    result_set =  Xplain::KeywordSearch.new.get_results(inputs: input, keyword:  'common_keyword')
    
    
    assert_same_items_set input.last_level, result_set
  end
  
  def test_disjunctive_keyword_search
    expected_results = Set.new(create_nodes [ Xplain::Entity.new(server: @papers_server, id: '_:p3'), Xplain::Entity.new(server: @papers_server, id: '_:paper1')])
    result_set =  Xplain::KeywordSearch.new.get_results(server: @papers_server, keyword:  'paper3_keyword|paper1_keyword')
    
    assert_same_items_set expected_results, result_set
  end
  
  def test_conjunctive_keyword_search
    expected_results = Set.new(create_nodes [Xplain::Entity.new(server: @papers_server, id: '_:p2')])
    result_set =  Xplain::KeywordSearch.new.get_results(server: @papers_server, keyword:  'paper2_keyword1.*paper2_keyword2')
    
    assert_same_items_set expected_results, result_set

  end
  
  def test_conjunctive_keyword_search_two_label_properties
    Xplain::Visualization.current_profile.label_for_type( 
      "http://www.w3.org/2000/01/rdf-schema#Resource",
      "http://www.w3.org/1999/02/22-rdf-syntax-ns#label", 
      "_:alternative_label_property" 
    )
      
   
    expected_results = Set.new(create_nodes [Xplain::Entity.new(server: @papers_server, id: '_:p3')])
    result_set =  Xplain::KeywordSearch.new.get_results(server: @papers_server, keyword:  'common_keyword.*paper3_keyword2')
    
    assert_same_items_set expected_results, result_set
  end
end