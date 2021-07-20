# require './test/xpair_unit_test'
#
# class RankTest < XpairUnitTest
#
#   def setup
#     @graph = RDF::Graph.new do |graph|
#       graph << [RDF::URI("_:p1"),  RDF::URI("_:r1"), RDF::URI("_:o1")]
#       graph << [RDF::URI("_:p1"),  RDF::URI("_:r1"), RDF::URI("_:o2")]
#       graph << [RDF::URI("_:p2"),  RDF::URI("_:r1"), RDF::URI("_:o2")]
#       graph << [RDF::URI("_:p3"),  RDF::URI("_:r1"), RDF::URI("_:o3")]
#       graph << [RDF::URI("_:p4"),  RDF::URI("_:r2"), RDF::URI("_:o4")]
#       graph << [RDF::URI("_:p4"),  RDF::URI("_:r2"), RDF::URI("_:o5")]
#       graph << [RDF::URI("_:p5"),  RDF::URI("_:r2"), RDF::URI("_:o6")]
#     end
#
#     @server = RDFDataServer.new(@graph)
#     #
#     # @correlate_graph = RDF::Graph.new do |graph|
#     #   graph << [RDF::URI("_:o1"), RDF::URI("_:r1"), RDF::URI("_:p1")]
#     #   graph << [RDF::URI("_:o1"), RDF::URI("_:r1"), RDF::URI("_:p3")]
#     #   graph << [RDF::URI("_:o2"), RDF::URI("_:r1"), RDF::URI("_:p3")]
#     #   graph << [RDF::URI("_:p1"), RDF::URI("_:r1"), RDF::URI("_:p2")]
#     #   graph << [RDF::URI("_:o2"), RDF::URI("_:r1"), RDF::URI("_:p2")]
#     # end
#     #
#     # @correlate_server = RDFDataServer.new(@correlate_graph)
#     #
#     # @keyword_refine_graph = RDF::Graph.new do |graph|
#     #   graph << [RDF::URI("_:p1"),  RDF::URI("_:r1"), "keyword1"]
#     #   graph << [RDF::URI("_:p1"),  RDF::URI("_:r1"), "keyword2 keyword 3"]
#     #   graph << [RDF::URI("_:p2"),  RDF::URI("_:r1"), RDF::URI("_:o2")]
#     #   graph << [RDF::URI("_:p3"),  RDF::URI("_:r1"), RDF::URI("_:o3")]
#     #   graph << [RDF::URI("_:p4"),  RDF::URI("_:r2"), RDF::URI("_:o4")]
#     #   graph << [RDF::URI("_:p4"),  RDF::URI("_:r2"), RDF::URI("_:o5")]
#     #   graph << [RDF::URI("_:p5"),  RDF::URI("_:r2"), RDF::URI("_:o6")]
#     # end
#     #
#     # expected_extension = {
#     #   Entity.new("_:a1") => Set.new([3]),
#     #   Entity.new("_:a2") => Set.new([2])
#     # }
#
#     papers_graph = RDF::Graph.new do |graph|
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p2")]
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p4")]
#       graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p2")]
#       graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
#       graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
#       graph << [RDF::URI("_:p7"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
#       graph << [RDF::URI("_:p7"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
#       graph << [RDF::URI("_:p8"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
#       graph << [RDF::URI("_:p8"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
#       graph << [RDF::URI("_:p9"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
#       graph << [RDF::URI("_:p10"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
#
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:submittedTo"), RDF::URI("_:journal1")]
#
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:author"),RDF::URI("_:a1") ]
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:author"),RDF::URI("_:a2") ]
#       graph << [RDF::URI("_:p2"),  RDF::URI("_:author"), RDF::URI("_:a1")]
#       graph << [RDF::URI("_:p3"),  RDF::URI("_:author"), RDF::URI("_:a2")]
#       graph << [RDF::URI("_:p5"),  RDF::URI("_:author"), RDF::URI("_:a1")]
#       graph << [RDF::URI("_:p5"),  RDF::URI("_:author"), RDF::URI("_:a2")]
#       graph << [RDF::URI("_:p6"),  RDF::URI("_:author"), RDF::URI("_:a2")]
#
#       graph << [RDF::URI("_:p2"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal1")]
#       graph << [RDF::URI("_:p3"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal2")]
#       graph << [RDF::URI("_:p4"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal3")]
#
#       graph << [RDF::URI("_:journal1"),  RDF::URI("_:releaseYear"), 2005]
#       graph << [RDF::URI("_:journal2"),  RDF::URI("_:releaseYear"), 2010]
#       graph << [RDF::URI("_:journal3"),  RDF::URI("_:releaseYear"), 2007]
#
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k1")]
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k2")]
#       graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k3")]
#
#       graph << [RDF::URI("_:p2"),  RDF::URI("_:keywords"), RDF::URI("_:k3")]
#       graph << [RDF::URI("_:p3"),  RDF::URI("_:keywords"), RDF::URI("_:k2")]
#       graph << [RDF::URI("_:p5"),  RDF::URI("_:keywords"), RDF::URI("_:k1")]
#
#       graph << [RDF::URI("_:p2"),  RDF::URI("_:publicationYear"), 2000]
#       graph << [RDF::URI("_:p3"),  RDF::URI("_:publicationYear"), 1998]
#       graph << [RDF::URI("_:p4"),  RDF::URI("_:publicationYear"), 2010]
#     end
#
#     @papers_server = RDFDataServer.new(papers_graph)
#
#   end
#
#   def test_alhpa_rank
#     test_set = Xset.new('test', '')
#
#     test_set.add_item Entity.new("_:p4")
#     test_set.add_item Entity.new("_:p2")
#     test_set.add_item Entity.new("_:a4")
#     test_set.add_item Entity.new("_:b4")
#
#     expected_items = [
#       Entity.new("_:p4"),
#       Entity.new("_:p2"),
#       Entity.new("_:b4"),
#       Entity.new("_:a4")
#     ]
#
#
#     assert_equal expected_items, test_set.rank{|rf| rf.alpha_rank}.each_item
#
#   end
#
#   def test_rank_by_image
#
#     test_set1 = Xset.new('test', '')
#
#     l1 = Xpair::Literal.new(30)
#     l1.index = Indexing::Entry.new('root')
#     l1.index.children = [Indexing::Entry.new(Entity.new('_:p1'))]
#     l1.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2005))]
#
#
#     l2 = Xpair::Literal.new(20)
#     l2.index = Indexing::Entry.new('root')
#     l2.index.children = [Indexing::Entry.new(Entity.new('_:p2'))]
#     l2.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2006))]
#
#     l3 = Xpair::Literal.new(10)
#     l3.index = Indexing::Entry.new('root')
#     l3.index.children = [Indexing::Entry.new(Entity.new('_:p2'))]
#     l3.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2007))]
#
#     l4 = Xpair::Literal.new(40)
#     l4.index = Indexing::Entry.new('root')
#     l4.index.children = [Indexing::Entry.new(Entity.new('_:p1'))]
#     l4.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2008))]
#
#
#     test_set1.add_item l2
#     test_set1.add_item l1
#     test_set1.add_item l4
#     test_set1.add_item l3
#
#     # assert_equal [Entity.new('_:p2'), Entity.new('_:p4')], test_set1.rank(position: "domain"){|rf| rf.by_image}.each_item


#   end
#
#   def test_rank_by_domain
#
#     test_set1 = Xset.new('test', '')
#
#     l1 = Xpair::Literal.new(30)
#     l1.index = Indexing::Entry.new('root')
#     l1.index.children = [Indexing::Entry.new(Entity.new('_:p1'))]
#     l1.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2008))]
#
#
#     l2 = Xpair::Literal.new(20)
#     l2.index = Indexing::Entry.new('root')
#     l2.index.children = [Indexing::Entry.new(Entity.new('_:p2'))]
#     l2.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2003))]
#
#     l3 = Xpair::Literal.new(10)
#     l3.index = Indexing::Entry.new('root')
#     l3.index.children = [Indexing::Entry.new(Entity.new('_:p2'))]
#     l3.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2006))]
#
#     l4 = Xpair::Literal.new(40)
#     l4.index = Indexing::Entry.new('root')
#     l4.index.children = [Indexing::Entry.new(Entity.new('_:p1'))]
#     l4.index.children.first.children = [Indexing::Entry.new(Xpair::Literal.new(2004))]
#
#     test_set1.add_item l2
#     test_set1.add_item l1
#     test_set1.add_item l4
#     test_set1.add_item l3
#
#     # assert_equal [Entity.new('_:p2'), Entity.new('_:p4')], test_set1.rank(position: "domain"){|rf| rf.by_image}.each_item


#   end
#
#   def test_rank_by_schema_relation
#     test_set1 = Xset.new('test', '')
#     test_set1.add_item Entity.new("_:p4")
#     test_set1.add_item Entity.new("_:p3")
#     test_set1.add_item Entity.new("_:p2")
#
#     test_set1.server = @papers_server
#


#
#   end
#
#   def test_rank_empty_images
#     test_set1 = Xset.new('test', '')
#     test_set1.add_item Entity.new("_:paper1")
#     test_set1.add_item Entity.new("_:p4")
#     test_set1.add_item Entity.new("_:p3")
#     test_set1.add_item Entity.new("_:p2")
#
#     test_set1.server = @papers_server
#
#     rs = test_set1.rank{|gf| gf.by_relation(relations: [SchemaRelation.new("_:publishedOn", @papers_server)])}

#
#   end
#
#   def test_rank_by_two_steps
#     test_set1 = Xset.new do |s|
#       s.extension = {
#         Entity.new("_:paper1") => {},
#         Entity.new("_:p4") => {},
#         Entity.new("_:p2") => {},
#         Entity.new("_:p3") => {}
#       }
#       s.server = @papers_server
#     end
#     expected_extension = {
#       Entity.new("_:p2") => {},
#       Entity.new("_:p3") => {},
#       Entity.new("_:p4") => {},
#       Entity.new("_:paper1") => {}
#     }
#
#     set1 = test_set1.pivot_forward(relations: [Relation.new("_:publishedOn")])
#     set2 = set1.pivot_forward(relations: [Relation.new("_:releaseYear")])
#     rs = test_set1.rank{|gf| gf.by_relation(relations: [set2, set1])}
#     HashHelper.print_hash(rs.extension)
#     assert_equal expected_extension, rs.extension
#   end
#
#   def test_pivot_map_rank
#     test_set1 = Xset.new do |s|
#       s.extension = {
#         Entity.new("_:p7") => {},
#         Entity.new("_:paper1") => {},
#         Entity.new("_:p9") => {}
#
#       }
#       s.server = @papers_server
#     end
#     expected_extension = {
#       Entity.new("_:paper1") => {},
#       Entity.new("_:p7") => {},
#       Entity.new("_:p9") => {}
#     }
#
#     set1 = test_set1.pivot_forward(relations: [Relation.new("_:cite")])
#     set2 = set1.map{|mf| mf.count}
#     rs = test_set1.rank{|gf| gf.by_relation(relations: [set2])}
#     HashHelper.print_hash(rs.extension)
#     assert_equal expected_extension, rs.extension
#
#   end
#
#   def test_group_by_rank
#     test_set1 = Xset.new do |s|
#       s.extension = {
#         Entity.new("_:paper1") => {},
#         Entity.new("_:p8") => {},
#         Entity.new("_:p7") => {}
#
#       }
#       s.server = @papers_server
#     end
#
#     set1 = test_set1.group{|g| g.by_relation(relations: [Relation.new("_:cite")])}
#     set2 = set1.map{|mf| mf.count}
#     rs = set1.rank{|gf| gf.by_relation(relations: [set2])}

#     assert_equal [Entity.new("_:p5"), Entity.new("_:p3"), Entity.new("_:p2")], rs.extension.keys.to_a
#
#   end
#
#
# end