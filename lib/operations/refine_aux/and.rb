module RefineAux
  class And < CompositeFilter

    def filter(node, child_filters = @filters)
      r = child_filters.inject(true) do |previous_boolean, filter|
        previous_boolean && filter.filter(node)
      end
      
      r
    end
  end
end
