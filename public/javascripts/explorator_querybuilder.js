//Adds the selection behaviour to all properties and classes
function querybuilderselection(){
    $('.querybuildertool').each(function(item){
        item.onclick = function(e){
            $('qcontainer').show();
            
        };
    });
    $('.removerelation').each(function(item){
        item.onclick = function(e){
            if (item.up('.relation') == undefined) {
                item.up('.qcontainer').down('.relation').immediateDescendants().invoke('remove');
            }
            else {
                item.up('.tuple').remove();
            }
            e.stopPropagation();
        };
        curlbracket();
        
    });
    $('.querybuilderresource').each(function(item){
        item.onclick = function(e){
            if ($('.SELECTED').size() > 1) {
                alert('Select only one resource.');
                return;
            }
            else 
                if ($('.SELECTED').size() == 0) {
                    return;
                }
            var selected = $('.SELECTED').first();
            //Add a property and object for a resource selected.
            //If the resource is a property, just the value of this resource must be update.
            //  $('.addproperty').each(function(item){
            if (item.hasClassName('literal')) {
                return;
            }
            if (selected.hasClassName('property') && item.hasClassName('class')) {
                var literal = false;
                if (selected.hasClassName('datatypeproperty')) {
                    literal = true;
                }
                ajax_insert(item.up("table").select(".relation").first(), '/querybuilder/relation?literal=' + literal + '&uri=' + Element.resource($('.SELECTED').first()), 'refreshSet(true)');
                $('.SELECTED').invoke('removeClassName', 'SELECTED');
                
                ////////////////////////////////////////////////////////// 
            }
            else 
                if (item.hasClassName('class') && $('.SELECTED').first().hasClassName('class')) {
                    ajax_update_callback(item, '/querybuilder/resource?uri=' + Element.resource($('.SELECTED').first()), 'refreshSet(true)');
                    $('.SELECTED').invoke('removeClassName', 'SELECTED');
                    
                }
                else 
                    if (item.hasClassName('property') && $('.SELECTED').first().hasClassName('property')) {
                        ajax_update_callback(item, '/querybuilder/property?uri=' + Element.resource($('.SELECTED').first()), 'refreshSet(true)');
                        $('.SELECTED').invoke('removeClassName', 'SELECTED'); 
                    }
            curlbracket();
            init_all();
        };
    });
}

function refreshSet(){
    var q = querybuilder(true);
    ajax_create(q);
}

function curlbracket(){
    $('.curlbracket').each(function(item){
        // if (item.up('tr').select('.relation').first().childElements().size() > 1) {
        if (item.next().childElements().size() > 1) {
            item.show();
        }
        else {
            item.hide();
        }
    });
}
function setLiteral(input){
    Element.extend(input);
}

//Builds the query from the tree (structure query builder).
function querybuilder(preview){
    var i = 0;
    var q = "SemanticExpression.new(Query.new.distinct(:s,:p,:o).where(:s,:p,:o).where(:s,RDF::type,:o).";
    
    var root = Element.resource($('qcontainer').down('.node'));
    q = q + "where(:s,RDF::type,RDFS::Resource.new('" + root + "')).";
    $('qcontainer').down('.relation').immediateDescendants().each(function(item){
        var o = "o" + i;
        q = q + "where(:s,RDFS::Resource.new('" + Element.resource(item.down('.edge')) + "'),:" + o + ").";
        if ('%3Chttp%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23DatatypeProperty%3E' == Element.resource(item.down('.node'))) {
            if (item.down('input').value != '') {
                q = q + "filter_operator(:" + o + ",'=',"+item.down('input').value+").";
            }
        }else {
            q = q + "where(:" + o + ",RDF::type,RDFS::Resource.new('" + Element.resource(item.down('.node')) + "')).";
        }
        q = q + tree(item.down('.relation'), o);
        i++;
    });
    if (preview) {
        q = q + "filter_operator(:p,'=',RDF::type).limit(100).";
    }
    return q + "execute)";
}

function tree(relation, obj){
    var i = 0;
    var q = ""
    if (relation.down('.node') == undefined) 
        return q;
    relation.immediateDescendants().each(function(item){
        var o = obj + i;
        q = q + "where(:" + obj + ",RDFS::Resource.new('" + Element.resource(item.down('.edge')) + "'),:" + o + ").";
		 if ('%3Chttp%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23DatatypeProperty%3E' == Element.resource(item.down('.node'))) {
            if (item.down('input').value != '') {
                q = q + "filter_operator(:" + o + ",'=',"+item.down('input').value+").";
            }
        }
        else {
            q = q + "where(:" + o + ",RDF::type,RDFS::Resource.new('" + Element.resource(item.down('.node')) + "')).";
        }        
        q = q + tree(item.down('.relation'), o);
        i++;
    });
    return q;
}
