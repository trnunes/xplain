require './test/xplain_unit_test'
require './operations/rank_aux/by_image'
require './operations/rank_aux/by_text'

class Xplain::RankTest < XplainUnitTest


  def test_alhpa_rank
    nodes = []

    nodes << Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4"))
    nodes << Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    nodes << Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a4"))
    nodes << Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:b4"))

    expected_items = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a4")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:b4")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4"))
    ]


    actual_results = Xplain::Rank.new.get_results(input_nodes: nodes)


    assert_same_items expected_items, actual_results

  end

  def test_rank_by_image
    input_nodes = [
        Xplain::Node.new(item: Xplain::Entity.new(id: "_:journal2", server: @papers_server)),
        Xplain::Node.new(item: Xplain::Entity.new(id: "_:journal1", server: @papers_server))

    ]
    expected_results = [
        Xplain::Node.new(item: Xplain::Entity.new(id: "_:journal1", server: @papers_server)),
        Xplain::Node.new(item: Xplain::Entity.new(id: "_:journal2", server: @papers_server))
    ]
    relation = Xplain::SchemaRelation.new(id: "_:releaseYear")
    aux_function = RankAux::ByImage.new(relation: relation)
    
    actual_results = Xplain::Rank.new.get_results(input_nodes: input_nodes, function: aux_function)

    assert_same_items actual_results, expected_results 

    
  end

  def test_rank_by_level_items
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    i1p3 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    i1p1.children = [
        Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.1")), 
        Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.2"))
    ]
    i1p2.children = [
        Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2.1")), 
        Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2.2"))
    ]
    i1p3.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3.1"))]
    input = [i1p3, i1p2, i1p1]
    relation = Xplain::ResultSet.new nodes: input
    aux_function = RankAux::ByImage.new(relation: relation)
    expected_results = [i1p1, i1p2, i1p3]
    actual_results = Xplain::Rank.new.get_results(input_nodes: input, function: aux_function)
    assert_same_items expected_results, actual_results
  end
end