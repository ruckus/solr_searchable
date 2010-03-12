module SolrSearchable

  module InstanceMethods

    def to_solr_doc
      packet = {}
      packet[:id] = solr_id
      packet[:pk_i] = record_id(self)
      packet[solr_searchable_configuration[:type_field]] = self.class.name
      # iterate over each of this models defined solr fields
      #puts self.class.solr_searchable_configuration[:fields].inspect
      logger.debug "to_solr_doc: creating doc for class: #{self.class.name}, id: #{record_id(self)}"
      solr_searchable_configuration[:fields].each do |field_definition|
       type = field_definition.keys.first
       attribute = field_definition[type]
       solr_field = get_qualified_model_type(attribute)
       field_type = get_model_field_type(attribute)
       #solr_field = "#{attribute}_#{field_type}".to_sym
       value = get_field_value(attribute)
       value = set_value_if_nil(field_type) if value.to_s == ""
       packet[solr_field] = value
      end
      logger.debug("to_solr_doc: #{packet.inspect}")
      packet
    end
    
    def solr_save
      return true if skip_solr?
      #return unless self.class.solr_alive?
      logger.debug "solr_save: #{self.class.name}:#{record_id(self)}"
      m = Benchmark.measure do
        solr_add to_solr_doc
        solr_commit if solr_searchable_configuration[:auto_commit]        
      end
      logger.debug("[benchmark] solr_save (#{self.class.to_s}): #{m}")
      true
    end
    
    def solr_destroy
      logger.debug "solr_destroy: #{self.class.name}:#{record_id(self)}"
      solr_delete
      solr_commit if solr_searchable_configuration[:auto_commit]        
    end
    
    # Methods to control and query when ActiveRecord will trigger a Solr save - we dont always want too  
    def save_to_solr?; @wants_solr_save.nil? || @wants_solr_save == true; end  
    def skip_solr!; @wants_solr_save = false; end
    def skip_solr?; @wants_solr_save == false; end  
    def save_in_solr!; @wants_solr_save = true; end
    
    # Allows caller to over-ride the default Solr save callback, used like
    # some_record.skipping_solr do
    #    update_attribute(:counter, counter + 1)
    # end
    # Which would normally trigger a Solr save but if we know we want to only save a record
    # to the DB
    def skipping_solr 
      self.skip_solr!
      yield self
      self.save_in_solr!
    end
    
    # Solr id is <class.name>:<id> to be unique across all models
    def solr_id
      "#{self.class.name}:#{record_id(self)}"
    end
  end #ClassMethods
  
end #SolrSearchable