extends Node

func _ready():
	var rendering_device := RenderingServer.create_local_rendering_device()
	
	var input := PackedFloat32Array([1,22,3,4,5,6,37,8,9,10]) # Preparing our data and converting to bytes
	var input_bytes := input.to_byte_array() 
	
	# create a storage buffer resource ID for our input bytes
	var buffer := rendering_device.storage_buffer_create(input_bytes.size(), input_bytes)
	
	var shader_file = load("res://materials/shaders/kelp_compute.glsl")
	var shader_spirv = shader_file.get_spirv() # converts shader into SPIR-V machine code for the GPU
	var shader_RID := rendering_device.shader_create_from_spirv(shader_spirv) # gets resource ID for the shader

	# telling the rendering device to use the buffer
	var uniform := RDUniform.new() # uniform that will be assigned to the rendering device
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER # setting type to storage buffer
	uniform.binding = 0 # setting a binding that matches our shader file binding
	uniform.add_id(buffer) # adds the buffer resource ID to the uniform
	# creates the uniform set (must match the set in the shader file)
	var uniform_set := rendering_device.uniform_set_create([uniform], shader_RID, 0)
	
	# create a compute pipeline (steps for the GPU to run the shader?)
	var pipeline_RID = rendering_device.compute_pipeline_create(shader_RID) 
	
	var compute_list_id := rendering_device.compute_list_begin() # gets the index the shader is on the compute list (index = ID)
	
	rendering_device.compute_list_bind_compute_pipeline(compute_list_id, pipeline_RID) # binds pipeline to the compute list
	rendering_device.compute_list_bind_uniform_set(compute_list_id, uniform_set, 0) # bind buffer uniform to pipeline
	rendering_device.compute_list_dispatch(compute_list_id, 5, 1, 1) # sets the compute list to be executed with amount of groups/threads
	rendering_device.compute_list_end() # ends instructions
	
	rendering_device.submit() # sends rendering device to the GPU to execute
	rendering_device.sync() # gets the data from the GPU (will await it finishing if called immedietly)
	
	var output_bytes := rendering_device.buffer_get_data(buffer)
	var output := output_bytes.to_float32_array()
	print("Input: ", input)
	print("Output: ", output)
