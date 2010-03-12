module SolrSearchable
  module CommonMethods
    
    # Converts field types into Solr types
    def get_solr_field_type(field_type)
      if field_type.is_a?(Symbol)
        case field_type
          when :float:          return "f"
          when :integer:        return "i"
          when :boolean:        return "b"
          when :string:         return "s"
          when :date:           return "d"
          when :range_float:    return "rf"
          when :range_integer:  return "ri"
          when :range_double:   return "rdb"
          when :facet:          return "facet"
          when :text:           return "t"
          when :alpha_sort:     return "alpha_sort"
          when :facet:          return "fc"
        else
          raise "Unknown field_type symbol: #{field_type}"
        end
      elsif field_type.is_a?(String)
        return field_type
      else
        raise "Unknown field_type class: #{field_type.class}: #{field_type}"
      end
    end
    
    def get_field_value(attribute)
      self.instance_variable_get("@#{attribute.to_s}".to_sym) || self.send(attribute.to_sym)
    end
    
    # Given a model attribute like +:name+ and its indexed as of type :text turns it into its Solr field name
    # like 'name_t'
    def get_qualified_model_type(attribute)
      field_type = get_solr_field_type(get_model_field_type(attribute))
      "#{attribute}_#{field_type}".to_sym
    end
    
    def get_model_field_type(attribute)
      self.solr_searchable_column_types[attribute]
    end
    
    
    # Sets a default value when value being set is nil.
    def set_value_if_nil(field_type)
      case field_type
        when "b", :boolean:                        return "false"
        when "s", "t", "d", :date, :string, :text: return ""
        when "f", "rf", "rdb", :float, :range_float, :range_double: return 0.00
        when "i", "ri", :integer, :range_integer:  return 0
      else
        return ""
      end
    end
    
    # Returns the id for the given instance
    def record_id(object)
      eval "object.#{object.class.primary_key}"
    end
    
    def solr_add(data)
      return false unless solr_alive?
      rsolr = SolrSearchable::IO.get_connection
      rsolr.add data
    end
    
    def solr_delete
      return false unless solr_alive?
      rsolr = SolrSearchable::IO.get_connection      
      rsolr.delete_by_id solr_id
    end
    
    def solr_commit
      return false unless solr_alive?
      SolrSearchable::IO.get_connection.commit
    end

    def solr_optimize
      return false unless solr_alive?
      SolrSearchable::IO.get_connection.update
    end
    
    def solr_ping
      begin
        response = SolrSearchable::IO.get_connection.request('/admin/ping')
        response['status'] && response['status'] == 'OK'
      rescue => ex
        return false
      end
    end
    
    def solr_alive?
      solr_ping
    end
    
  end
end # SolrSearchable