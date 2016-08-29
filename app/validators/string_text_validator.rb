class StringTextValidator < ActiveModel::Validator

  def validate(record)
    invalid_characters = /[\t\n]/i
    record.attributes.each_pair do |attr_name, attr_value|
      attr_type = record.class.columns_hash[attr_name].type
      if ([:string, :text].include?(attr_type) &&
          attr_value =~ invalid_characters)
        record.errors[attr_name] << "contains an invalid character (like a tab or line-breaks)"
      end
    end
  end

end