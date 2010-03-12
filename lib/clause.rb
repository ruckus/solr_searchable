module SolrSearchable
  
  ESCAPE_CHARS = /([\+\-!(){}\[\]\^\|"~*\?\;\&\\])/
  
  class Clause
    
    OR = :OR
    AND = :AND
    
    def initialize(model = nil)
      raise StandardError, 'missing Model argument' if model.nil?
      @model = model
      @and_clauses = []
      @or_clauses = []
    end
    
    def to_s
      query = ""
      return nil if @and_clauses.length == 0 && @or_clauses.length == 0
      @and_clauses.compact!
      @or_clauses.compact!
      have_ands = @and_clauses.length > 0
      have_ors = @or_clauses.length > 0
      have_both = have_ands && have_ors
      ands = "#{@and_clauses.join(" AND ")}"
      ors = "#{@or_clauses.join(" OR ")}"
      if have_ands && !have_ors
        query = " (#{ands}) "
      end

      if have_ors && !have_ands
        query = " (#{ors}) "
      end

      if have_both
        query = "((#{ors}) AND (#{ands}))"
      end
      query
    end

    def and(*objects)
      objects.each do |object|
        if object.is_a?(Clause)
          @and_clauses << object.to_s
        elsif object.is_a?(Hash)
          generate_clause_set(object, AND) do |solr_field, value, boost|
            build_terms_query(solr_field, value, boost)
          end
        end
      end
      self     
    end

    
    def or(*objects)
      objects.each do |object|
        if object.is_a?(Clause)
          @or_clauses << object.to_s
        else      
          generate_clause_set(object, OR) do |solr_field, value, boost|
            build_terms_query(solr_field, value, boost)
          end
        end
      end
      self     
    end
    
    def raw_and(*objects)
      objects.each do |object|
        if object.is_a?(Clause)
          @and_clauses << object.to_s
        else
          generate_clause_set(object, AND) do |solr_field, value, boost|
            "#{solr_field}:('#{escape(value)}')#{boost ? "^#{boost}" : ""}"
          end
        end
      end
      self
    end
    
    def raw_or(*objects)
      objects.each do |object|
        if object.is_a?(Clause)
          @or_clauses << object.to_s
        else
          generate_clause_set(object, OR) do |solr_field, value, boost|
            "#{solr_field}:('#{escape(value)}')#{boost ? "^#{boost}" : ""}"
          end
        end
      end
      self
    end
    
    def generate_clause_set(criteria, operator, &block)
      interior_clause_set = []
      if criteria.is_a?(Hash)
        criteria.each_pair do |field, data|
          boost = nil
          if data.is_a?(Array)
            value = data.first
            boost = data.last
          else
            value = data
          end
          solr_field = @model.get_qualified_model_type(field)
          result = yield solr_field, value, boost
          if operator == AND
            @and_clauses << result
          elsif operator == OR
            @or_clauses << result
          end
        end
      end
    end
    
    def self.clean!(query)
      query ||= ''
      #cleaned = query.gsub(/[^a-zA-Z0-9\s]/, '').downcase.strip
      cleaned = query.downcase.strip
      cleaned = escape(cleaned)
      if cleaned.blank?
        return nil
      end
      #squash duplicate spaces
      cleaned.gsub!(/\s+/, ' ')
      Rails.logger.info("SolrSearchable::Clause clean: #{query} -> #{cleaned}")
      cleaned
    end
    
    def self.escape(value)
      # remove colons
      s = value.dup
      s.gsub!(':', '')
      s.gsub(SolrSearchable::ESCAPE_CHARS, '\\\\\1')
    end
    
    def escape(value)
      self.class.escape(value)
    end
    
    def build_terms_query(field, terms, boost = nil, opts = {})
      self.class.build_terms_query(field, terms, boost, opts = {})
    end
    
    # Builds a Solr compatible query for searching on multiple terms in a single field, e.g.
    # To match a 'name' field that contains both 'billy' and 'corgan' the query syntax is:
    #      name:(+billy +corgan)
    # and its called: build_terms_query(name, 'billy corgan')
    # (Notice that the term will be split on spaces)
    #
    # == Parameters
    # field<String>: The Solr field to search on
    # terms<Array or String>: Array of search terms, all of which should exist in the Solr Field
    #                         Or a string which will be split on whitespace
    # boost<Integer> : (optional) Lucene boost
    # options<Hash> : Accepted keys:
    #  :operator<Boolean> Whether or not to generate a query where multiple terms are ORed together
    # The default is to basically generate an AND query
    def self.build_terms_query(field, terms, boost = nil, opts = {})      
      opts[:operator] ||= :and
      if terms.is_a?(String)
        terms = terms.strip.split(/\s/)
      end
      return "" if terms.blank?
      if opts[:operator] == :or
        clauses = []
        terms.each do |term|
          clauses << "'#{escape(term)}'"
        end
        term_clause = clauses.join(" || ")      
      else
        if terms.is_a?(Array)
          term_clause = terms.map { |t| " +'#{escape(t)}'" }
        elsif terms.is_a?(Fixnum)
          term_clause = " +#{terms}"
        else
          term_clause = " +#{terms}"
        end
      end
      "#{field}:(#{term_clause})#{boost ? "^#{boost}" : ""}"
    end
    
  end
  
end # SolrSearchable