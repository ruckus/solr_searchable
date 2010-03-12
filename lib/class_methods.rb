require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/parser_methods'

module SolrSearchable

  module ClassMethods    
    include ParserMethods
    include CommonMethods
    
    def new_solr_clause
      SolrSearchable::Clause.new(self)
    end
    
    # Called via a model, e.g. Profile.find_by_solr
    def find_by_solr(query, options = {})
      query_options = generate_query_options(query, options)
      environment_options = solr_searchable_default_query_options.merge(options)
      SolrSearchable::Handler::Select.new(query_options, self, environment_options).execute
    end
    
    def solr_query(query, options = {})
      query_options = generate_query_options(query, options)
      SolrSearchable::Handler::Select.new(query_options, self, {:format => :raw}).execute
    end
    
    def count_by_solr(query, options = {})        
      query_options = generate_query_options(query, options)
      environment_options = solr_searchable_default_query_options.merge(options)
      result = SolrSearchable::Handler::Select.new(query_options, self, {:format => :raw}).execute
      result[:total_hits]
    end
    
    # this is a copy of WillPaginate#paginate specialized for "find_by_solr"
    def paginate_by_solr(*args, &block)
      options = args.extract_options!
      options.symbolize_keys!
      page, per_page, total_entries = wp_parse_options(options)

      WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
        count_options = options.except(:page, :per_page, :total_entries, :finder)
        find_options = count_options.except(:count).update(:offset => pager.offset, :limit => pager.per_page)
        
        args << find_options.symbolize_keys # else we may break something
        begin
          found = find_by_solr(*args, &block)
          pager.total_entries = found[:total_hits]
          # Highlights?
          #pager.highlights = found.highlights if found.highlights
          found = found[:docs]
          pager.replace found
        rescue => ex
          return pager.replace([])
          Rails.logger.info("Search error: #{ex.message}")
        end
      end
    end
    
    def rebuild_solr_index(batch_size=1000)
      items_processed = 0
      self.find_in_batches(:batch_size => batch_size) do |group|
        add_batch = group.collect { |content| content.to_solr_doc }
        if add_batch.size > 0
          solr_add(add_batch)
          solr_commit
          logger.debug(" ** SOLR COMMIT")
          items_processed += add_batch.size
        end
        logger.debug "#{items_processed} items for #{self.name} have been batch added to index."            
      end # self.find_in_batches
      logger.debug items_processed > 0 ? "Index for #{self.name} has been rebuilt" : "Nothing to index for #{self.name}"      
    end
    
  end #ClassMethods
  
end #SolrSearchable