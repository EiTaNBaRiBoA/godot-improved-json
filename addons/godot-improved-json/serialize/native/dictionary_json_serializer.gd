extends JSONSerializer


func _get_id() -> Variant:
	return TYPE_DICTIONARY


func _serialize(instance: Variant, impl: JSONSerializationImpl) -> Variant:
	assert(instance is Dictionary, "instance not of type Dictionary")
	
	if instance.is_empty():
		return {}
	
	var dict: Dictionary = instance as Dictionary
	
	var serialized: Dictionary = {}
	
	for key: Variant in instance:
		# NOTE: JSON keys need to be strings, so we use stringify here instead
		var serialized_key: String = impl.stringify(key)
		var serialized_value: Variant = impl.serialize(instance[key])
		
		serialized[serialized_key] = serialized_value
	
	var result: Dictionary = {
		"k": {},
		"v": {},
		"d": serialized,
	}
	
	# Set key type
	if dict.is_typed_key():
		result.k = GodotJSONUtil.create_type_dict(impl, dict.get_typed_key_builtin(), 
		dict.get_typed_key_class_name(), dict.get_typed_key_script())
	
	# Set value type
	if dict.is_typed_value():
		result.v = GodotJSONUtil.create_type_dict(impl, dict.get_typed_value_builtin(), 
		dict.get_typed_value_class_name(), dict.get_typed_value_script())
	
	return result



func _deserialize(serialized: Variant, impl: JSONSerializationImpl) -> Variant:
	assert(serialized is Dictionary, "serialized (%s) not of type Dictionary" % serialized)
	assert(serialized.has("d"), "serialized (%s) missing key 'd'" % serialized)
	assert(serialized.has("k"), "serialized (%s) missing key 'k'" % serialized)
	assert(serialized.has("v"), "serialized (%s) missing key 'v'" % serialized)
	
	var dict: Dictionary
	
	# Untyped dictionary
	if dict.k.is_empty() && dict.v.is_empty():
		dict = {}
	else: # Typed dictionary
		var key_type: Variant.Type
		var key_class: String
		var key_script: Script
		if dict.k.has("t"):
			key_type = dict.k.t
		elif dict.k.has("c"):
			key_type = TYPE_OBJECT
			key_class = dict.k.c
		elif dict.k.has("i"):
			var config_id: StringName = StringName(dict.k.i)
			var config: JSONObjectConfig = impl.object_config_registry.get_config_by_id(config_id)
			assert(config != null, ("error determining dictionary key type; no JSONObjectConfig " + \
			"found with id (%s) when deserializing dictionary (%s)") % [config_id, serialized])
			var script: Script = config.get_class_script()
			assert(script != null, ("error determining dictionary key type; no script found " + \
			"for config (%s) when deserializing dictionary (%s)") % [config, serialized])
			
			key_type = TYPE_OBJECT
			key_class = script.get_instance_base_type()
			key_script = script
		else:
			key_type = TYPE_NIL
		
		var value_type: Variant.Type
		var value_class: String
		var value_script: Script
		if dict.v.has("t"):
			value_type = dict.v.t
		elif dict.v.has("c"):
			value_type = TYPE_OBJECT
			value_class = dict.v.c
		elif dict.v.has("i"):
			var config_id: StringName = StringName(dict.v.i)
			var config: JSONObjectConfig = impl.object_config_registry.get_config_by_id(config_id)
			assert(config != null, ("error determining dictionary value type; no JSONObjectConfig " + \
			"found with id (%s) when deserializing dictionary (%s)") % [config_id, serialized])
			var script: Script = config.get_class_script()
			assert(script != null, ("error determining dictionary value type; no script found " + \
			"for config (%s) when deserializing dictionary (%s)") % [config, serialized])
			value_type = TYPE_OBJECT
			value_class = script.get_instance_base_type()
			value_script = script
		else:
			value_type = TYPE_NIL
		
		dict = Dictionary({}, key_type, key_class, key_script, value_type, value_class, value_script)
	
	_deserialize_into(serialized, dict, impl)
	
	return dict


func _deserialize_into(serialized: Variant, instance: Variant, impl: JSONSerializationImpl) -> void:
	assert(instance is Dictionary, "instance not of type Dictionary")
	assert(serialized is Dictionary, "serialized not of type Dictionary")
	assert(serialized.has("d"), "serialized (%s) missing key 'd'" % serialized)
	
	var dict: Dictionary = serialized.d
	for stringified_key: Variant in dict:
		# JSON keys must be strings so we use parse instead of deserialize
		assert(stringified_key is String, ("key (%s) not of type String " + \
		"for serialized Dictionary (%s)") % [stringified_key, dict])
		var key: Variant = impl.parse(stringified_key)
		var value: Variant = impl.deserialize(dict[stringified_key])
		
		instance[key] = value