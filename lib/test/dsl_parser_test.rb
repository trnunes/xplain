require './test/xplain_unit_test'
require './operations/refine_aux/filter_factory'

require './operations/refine_aux/generic_filter'
require './operations/refine_aux/relation_filter'
require './operations/refine_aux/composite_filter'
require './operations/group_aux/grouping_relation'

require './execution/dsl_parser'

class  DSLParserTest < XplainUnitTest
  
  def setup
    super
    @parser = DSLParser.new
  end
  
  def test_parse_resultset_only_extension
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    
    actual_code = @parser.to_ruby(test_rs)
    
    expected_code = "Xplain::ResultSet.load(\"test\")"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
  
    
    assert_equal expected_code.gsub(" ", ""), actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
  end
  
  def test_parse_keyword_search
    keyword_search_operation = Xplain::KeywordSearch.new(keyword_phrase:  'paper1_keyword')
    
    actual_code = @parser.to_ruby(keyword_search_operation)
    
    expected_code = "Xplain::KeywordSearch.new(keyword_phrase:'paper1_keyword')"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
  
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code


  end
  
  def test_parse_pivot
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.pivot(){relation "_:author"}
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").pivot do relation \"_:author\";end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code
  end
  
  def test_parse_pivot_params
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.pivot(level: 3, arg1: "arg1", arg2: "arg2"){relation "_:author"}
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").pivot(level: 3, arg1: 'arg1', arg2: 'arg2') do relation \"_:author\";end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code
  end

  def test_parse_refine
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.refine do
      equals do
        relation "_:author"
        entity "_:p2"
      end
    end
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").refine do equals do relation \"_:author\"; entity \"_:p2\" end end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code

  end
  
  def test_parse_refine_cfilter
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.refine do
      c_filter name: "test_cfilter", code: "|i|i.id == \"test_id\""
    end
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").refine do c_filter(name: 'test_cfilter', code: '|i|i.id == \"test_id\"')do end end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code

  end
  
  def test_parse_refine_visual
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.refine(visual: true) do
      equals do
        relation "_:author"
        entity "_:p2"
      end
    end
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").refine(visual:            true) do equals do relation \"_:author\"; entity \"_:p2\" end end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code

  end

  def test_parse_refine_and
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.refine do
      And do [
        equals do
          relation "_:cite", "_:author"
          entity "_:a1"
        end,
        equals do
          relation "_:cite", "_:author"
          entity "_:a2"
        end
      ]
      end
    end
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").refine do
      And do [
        equals do
          relation \"_:cite\", \"_:author\";
          entity \"_:a1\"
        end,
        equals do
          relation \"_:cite\", \"_:author\";
          entity \"_:a2\"
        end
      ]
      end
    end"

    assert_nothing_raised do
      eval(expected_code)
    end

    assert_nothing_raised do
      eval(actual_code)
    end
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code

  end
  
  def test_parse_group
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.group{by_image{relation "_:author"}}
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").group do by_image do relation \"_:author\";end end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
  
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code
 
  end

  def test_parse_map_count
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.aggregate{count}
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").aggregate do count do end end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
  
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code
 
  end
  
  def test_parse_args_aux_function
    test_rs = Xplain::ResultSet.new(id: "test")
    test_rs.save
    test_op = test_rs.rank(order: :desc, level: 2){by_level(3)}
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code = "Xplain::ResultSet.load(\"test\").rank(order: :desc, level: 2) do by_level(3) do end end"
    assert_nothing_raised do
      eval(expected_code)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
  
    expected_code = expected_code.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
    assert_equal expected_code, actual_code.gsub(" ", "").gsub("\n", ""), "\nExpected:" + expected_code + " \n Actual:  " + actual_code
    puts "-----CODE-----"
    puts actual_code
 
  end
  
  def test_parse_unite
    test_rs1 = Xplain::ResultSet.new(id: "test1")
    test_rs1.save
    test_rs2 = Xplain::ResultSet.new(id: "test2")
    test_rs2.save

    test_op = test_rs1.unite(test_rs2)
    
    actual_code = @parser.to_ruby(test_op)
    
    expected_code1 = "Xplain::Unite.new([Xplain::ResultSet.load(\"test1\"), Xplain::ResultSet.load(\"test2\")])"
    expected_code2 = "Xplain::Unite.new([Xplain::ResultSet.load(\"test2\"), Xplain::ResultSet.load(\"test1\")])"
    expected_code1.gsub!(" ", "").gsub!("\n", "")
    expected_code2.gsub!(" ", "").gsub!("\n", "")
    actual_code.gsub!(" ", "").gsub!("\n", "")
    assert_nothing_raised do
      eval(expected_code1)
    end
    assert_nothing_raised do
      eval(expected_code2)
    end
    assert_nothing_raised do
      eval(actual_code)
    end
    
  
    assert_true((expected_code1 == actual_code || expected_code2 == actual_code), actual_code)
    puts "-----CODE-----"
    puts actual_code

    
  end
end