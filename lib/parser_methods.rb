module SolrSearchable
  module ParserMethods

  protected
  
  def generate_query_options(query, options = {})
    query_options = {}
    query_options[:q] = query
    query_options[:fl] = [solr_searchable_configuration[:primary_key_field], 'score', 'id']
    if options[:fl] && options[:fl].is_a?(Array)
      query_options[:fl].concat(options[:fl])
    end
    query_options[:fq] = ["#{solr_searchable_configuration[:type_field]}:#{self.name}"]
    query_options[:start] = (options[:offset] || 0)
    query_options[:rows] = (options[:limit] || solr_searchable_configuration[:limit])  
    if options[:fq]
      query_options[:fq].concat(options[:fq]) 
    end
    query_options
  end # parse_query
  
  end #ParserMethods
end #SolrSearchable