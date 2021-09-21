require 'timeout'
require 'json'
class ExplorationController < ApplicationController

    before_filter :setup_input

    def setup_input
        if params[:graph]
            @dataserver = Xplain::RDF::DataServer.new(params)
            params.delete(:graph)
        end
        if params[:input]
            if !params[:input].first.is_a? Array
                params[:input] = [params[:input]]
            end
            @input = params[:input].map do |input|
                input.to_a.map do |dict|
                    item_class = dict[:type]
                    server = nil
                    if dict[:server]
                        server = Xplain::RDF::DataServer.new(graph: dict[:server])
                    end
                    dict[:server] = server || @dataserver

                    Xplain::Node.from_h(dict)
                end
            end
            # binding.pry
            params[:input] = @input
            params[:input_nodes] = @input.first
        end
        if params[:relation]
            params[:relation] = Xplain::Relation.create(params[:relation])
        end
    end
    
    def search
        
        respond_to do |format|

            begin
                keyword = params[:keyword]
                exact = params[:exact] == "true"
                result_nodes = Xplain::KeywordSearch.new.get_results(server: @dataserver, keyword: keyword, exact: exact)
                result_nodes_dict = result_nodes.map{|n| n.to_h}
                format.json{render :json => result_nodes_dict.to_json}
            rescue => exception
                format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
            end
        end
    end

    def pivot
        result_nodes = Xplain::Pivot.new.get_results(params)
        # binding.pry
        result_nodes_dict = result_nodes.map{|n| n.to_h}
        
        respond_to do |format|
            format.json{render :json => result_nodes_dict.to_json}
        end
    end

    def refine
        
        respond_to do |format|
            begin
                # binding.pry
                filter = Xplain::create_filter(params[:input_nodes], params[:filter])

                results = filter.filter()

                result_nodes_dict = results.map{|n| n.to_h}
                format.json{render :json => result_nodes_dict.to_json}    
            rescue => exception
                # binding.pry
                format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
            end
        end
    end

    def group

        respond_to do |format|
            begin
                aux_function_class = eval("GroupAux::#{params[:function]}")
                aux_function = aux_function_class.new(params)
                results = Xplain::Group.new.get_results(
                    input_nodes: @input_nodes, 
                    function: aux_function
                )
                result_nodes_dict = results.map{|n| n.to_h}
                format.json{render :json => result_nodes_dict.to_json}
            rescue => exception
                format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
            end
        end
    end

    def map
    respond_to do |format|
        begin
            map_operation = eval("Xplain::#{params[:function]}")
            results = map_operation.new.get_results(params)
            result_nodes_dict = results.map{|n| n.to_h}
            format.json{render :json => result_nodes_dict.to_json}
        rescue => exception
            format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
        end
    end
    end

    def rank
    respond_to do |format|
        begin
            if params[:function]
                rank_function = eval("RankAux::#{params[:function]}")
                params[:function] = rank_function.new(params)
            end
            results = Xplain::Rank.new.get_results(params)
            result_nodes_dict = results.map{|n| n.to_h}
            format.json{render :json => result_nodes_dict.to_json}
        rescue => exception
            format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
        end
    end
    end

    def unite
    respond_to do |format|
        begin
            results = Xplain::Unite.new.get_results(params)
            result_nodes_dict = results.map{|n| n.to_h}
            format.json{render :json => result_nodes_dict.to_json}
        rescue => exception
            format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
        end
    end
    end

    def intersect
    respond_to do |format|
        begin
            results = Xplain::Intersect.new.get_results(params)
            
            result_nodes_dict = results.map{|n| n.to_h}
            format.json{render :json => result_nodes_dict.to_json}
        rescue => exception
            format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
        end
    end
    end

    def diff
    respond_to do |format|
        begin
            results = Xplain::Diff.new.get_results(params)
            result_nodes_dict = results.map{|n| n.to_h}
            format.json{render :json => result_nodes_dict.to_json}
        rescue => exception
            format.json{render :json => {error: [exception.message], stacktrace: exception.backtrace}}
        end
    end
    end

end
