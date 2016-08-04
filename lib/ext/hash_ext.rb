# Extension class for Hash
class Hash
  # Returns key case insensitively, if present
  def get_ikey(key_name)
    return self[nil] if key_name.nil?
    each do |key, value|
      next unless key.is_a?(String)
      return value if key.casecmp(key_name).zero?
    end

    nil
  end

  # Allows to check whether key is present, case insensitively
  def ikey?(key_name)
    return key?(nil) if key_name.nil?
    each do |key, _|
      next unless key.is_a?(String)
      return true if key.casecmp(key_name).zero?
    end

    false
  end

  # Normalizes all keys in hash to string
  def deep_stringify_keys
    manipulate = lambda do |item|
      retrieve_new_object(item, ->(it) { it.deep_stringify_keys }, ->(it) { it })
    end

    each_with_object({}) do |(key, value), result|
      result[key.to_s] =
        if value.instance_of?(Array)
          value.each_with_object([]) { |item, new_item| new_item << manipulate.call(item) }
        else
          manipulate.call(value)
        end
    end
  end

  # Normalizes all keys in hash to downcase
  def deep_downcase_keys
    manipulate = lambda do |item|
      retrieve_new_object(item, ->(it) { it.deep_downcase_keys }, ->(it) { it })
    end

    each_with_object({}) do |(key, value), result|
      result[key.downcase] =
        if value.instance_of?(Array)
          value.each_with_object([]) { |item, new_item| new_item << manipulate.call(item) }
        else
          manipulate.call(value)
        end
    end
  end

  # Returns carbon copy of original hash object
  def duplicate
    manipulate = lambda do |item|
      retrieve_new_object(item,
                          ->(it) { it.duplicate },
                          ->(it) { Marshal.load(Marshal.dump(it)) })
    end

    each_with_object({}) do |(key, value), result|
      result[key] =
        if value.instance_of?(Array)
          value.each_with_object([]) { |item, new_item| new_item << manipulate.call(item) }
        else
          manipulate.call(value)
        end
    end
  end

  private

  def retrieve_new_object(original, hash_operation, other_operation)
    original.instance_of?(Hash) ? hash_operation.call(original) : other_operation.call(original)
  end
end
