require './test/xplain_unit_test'
require './operation_factory'

class Xplain::FactoryTest < XplainUnitTest
 
    def test_single_pivot_inverse_path
        input_nodes = [Xplain::Node.new(item: Xplain::Entity.new("_:a1"))]
        root = Xplain::ResultSet.new(nodes: input_nodes)
        expected_results = Set.new([Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10")])
        json_str = '{
            "pivot": {
                "relation": "^_:author->^_:cite",
                "inputs": [{
                    "set": [
                        {
                            "type": "Entity",
                            "id": "_:a1"
                        }                    
                    ]
                }]
            }
        }'
        operation = OperationFactory.parse(json_str)
        assert_true operation.is_a? Xplain::Pivot
        assert_true operation.get_relation.is_a? Xplain::PathRelation
        assert_equal operation.get_relation.relations.size, 2
        assert_equal operation.get_relation.relations.first.id, "_:author"
        assert_equal operation.get_relation.relations[1].id, "_:cite"
        assert_true operation.get_relation.relations[1].inverse

        expected_results = Set.new([Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10")])
        actual_results = operation.execute()

        assert_false actual_results.children.empty?
        assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
    end

    def test_pivot_forward_and_backward_relation_paths
        input_nodes = [
            Xplain::Node.new(item: Xplain::Entity.new("_:journal1"))
        ]
        root = Xplain::ResultSet.new(nodes: input_nodes)

        expected_results = Set.new([Xplain::Entity.new("_:a1")])
        dsl_json = '{
            "pivot": {
                "inputs": [
                    {
                        "set": [
                            {
                                "type": "entity",
                                "id": "_:journal1"
                            }
                        ]
                    }
                ],
                "relation": "^_:publishedOn->_:author"
            }        
        }'
        operation = OperationFactory.parse(dsl_json)
        assert_true operation.is_a? Xplain::Pivot
        assert_true operation.get_relation.is_a? Xplain::PathRelation
        assert_equal operation.get_relation.relations.size, 2
        assert_equal operation.get_relation.relations.first.id, "_:publishedOn"
        assert_true operation.get_relation.relations.first.inverse
        assert_equal operation.get_relation.relations[1].id, "_:author"        

        expected_results = Set.new([Xplain::Entity.new("_:a1")])
        actual_results = operation.execute()
        assert_false actual_results.children.empty?
        assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})

    end

    #TODO implement
    def test_refine_equal_dsl
        dsl_json = '{
          "refine": {
            "inputs": [{
              "set":[          
                {
                  "type": "entity",
                  "id": "_:paper1"
    
                },
                {
                  "type": "entity",
                  "id": "_:p2"
                },
                {
                  "type": "entity",
                  "id": "_:p3"
                },
                {
                  "type": "entity",
                  "id": "_:p4"
                },
                {
                  "type": "entity",
                  "id": "_:p5"
                }
              ]
            }],
            "filters": [
              {
                "equals": {
                  "relation": "_:cite",
                  "entity": "_:p2" 
                }
              }
            ]
          }
        }'

        # op = OperationFactory.parse(dsl_json)
        # assert_equal op.class, Xplain::Refine
        # assert_equal op.auxiliar_function.class, RefineAux::Equal
        # assert_equal op.auxiliar_function.get_relation.id, "_:cite"
        # assert_equal op.auxiliar_funcion.get_values, [Xplain:Entity.new("_:p2")] 
    end
    
    #TODO implement
    def test_refine_equal_literal_dsl
        dsl_json = '{
          "refine": {
            "inputs": [{
              "set":[          
                {
                  "type": "entity",
                  "id": "_:journal1"
    
                },
                {
                  "type": "entity",
                  "id": "_:journal2"
                }
              ]
            }],
            "filters": [
              {
                "equals": {
                  "relation": "_:releaseYear",
                  "literal": "2005" 
                }
              }
            ]
          }
        }'
    end
    
    #TODO implement
    def test_refine_equal_path_size3_dsl
        dsl_json = '{
        "refine": {
            "inputs": [{
            "set":[          
                {
                "type": "entity",
                "id": "_:paper1"

                },
                {
                "type": "entity",
                "id": "_:p2"
                },
                {
                "type": "entity",
                "id": "_:p3"
                },
                {
                "type": "entity",
                "id": "_:p4"
                },
                {
                "type": "entity",
                "id": "_:p5"
                },
                {
                "type": "entity",
                "id": "_:p6"
                },
                {
                "type": "entity",
                "id": "_:p8"
                }
            ]
            }],
            "filters": [
            {
                "equals": {
                "relation": "^_:cite->_:submittedTo->_:releaseYear",
                "literal": "2005"
                }
            }
            ]
        }
        }'
    end

    #TODO implement
    def test_refine_cfilter_dsl
        dsl_json = '{
          "refine": {
            "inputs": 
              [
                {
                  "set":[
                    {
                      "type": "entity",
                      "id": "_:a1"
                    },
                    {
                      "type": "entity",
                      "id": "_:a2"
    
                    },
                    {
                      "type": "entity",
                      "id": "_:a3"
    
                    },
                    {
                      "type": "entity",
                      "id": "_:a4"
                    }
                  ]
                }
              ],
            
            "filters": [{"f": {"name": "by_id", "code": "|e| e.item.id == \"_:a1\""}}]
          }
        }'
    end
    
    #TODO implement  
    def test_refine_3levels_dsl
        dsl_json = '{
            "refine": {
            "inputs": [{
                "set": [
                {
                    "type": "entity",
                    "id": "_:journal1",
                    "children": [
                    
                    {
                        "type": "entity",
                        "id": "_:paper1"
                    },
                    {
                        "type": "entity",
                        "id": "_:p2"
                    }
                    
                    ]
                },
                {
                    "type": "entity",
                    "id": "_:journal2"
                    "children": [
                    {
                        "type": "entity",
                        "id": "_:p3"
                    },
                    {
                        "type": "entity",
                        "id": "_:p4"
                    }    
                    ]
                }
                ]
            }],
            "filters": [
                "equals":{
                "relation": "_:author",
                "entity": "_:a1"
                }
            ]
            }
        }'
    end
 
end