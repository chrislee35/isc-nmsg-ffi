require 'ipaddr'

module Nmsg
	class Timespec < FFI::Struct
		layout :tv_sec, :time_t,
		:tv_nsec, :long
	end
	
	class Message
		attr_reader :ptr
		def initialize(ptr)
			if ptr.is_a? FFI::Pointer
				@ptr = ptr
			elsif ptr.is_a? Nmsg::Msgmod
				@ptr = Nmsg.nmsg_message_init(ptr.ptr)
			else
				raise ArgumentError "Nmsg::Message.new requires either a pointer to a message or a Nmsg::Msgmod object"
			end
		end

		def time
			timeptr = Nmsg::Timespec.new
			Nmsg.nmsg_message_get_time(@ptr, timeptr)
			time = Nmsg.nmsg_timespec_to_double(timeptr)
			Time.at(time)
		end
		
		def time=(t)
			timeptr = Nmsg::Timespec.new
			timeptr.tv_sec = t.to_i
			timeptr.tv_usec = t.usec
			Nmsg.nmsg_message_set_time(@ptr, timeptr)
		end

		def msgmod
			Nmsg.nmsg_message_get_msgmod(@ptr)
		end
		
		def msgmod=(mmod)
			Nmsg.nmsg_message_set_msgmod(@ptr,mmod.ptr)
		end

		def vid
			Nmsg.nmsg_message_get_vid(@ptr)
		end
		
		def vid=(vid)
			Nmsg.nmsg_message_set_vid(@ptr,vid)
		end

		def msgtype
			Nmsg.nmsg_message_get_msgtype(@ptr)
		end

		def msgtype=(mtype)
			Nmsg.nmsg_message_set_msgtype(@ptr,mtype)
		end

		def source
			Nmsg.nmsg_message_get_source(@ptr)
		end

		def source=(s)
			Nmsg.nmsg_message_set_source(@ptr,s)
		end

		def operator
			Nmsg.nmsg_message_get_operator(@ptr)
		end

		def operator=(o)
			Nmsg.nmsg_message_set_operator(@ptr,o)
		end

		def group
			Nmsg.nmsg_message_get_group(@ptr)
		end

		def group=(g)
			Nmsg.nmsg_message_set_group(@ptr,g)
		end

		def to_pres
			presptr = FFI::MemoryPointer.new :pointer
			rv = Nmsg.nmsg_message_to_pres(@ptr, presptr, "\n")
			presptr.get_pointer(0).read_string
		end

		def payload
			Nmsg.nmsg_message_get_payload(@ptr).get_pointer(0).read_string
		end

		def payload=(pay)
			Nmsg.nmsg_message_set_payload(@ptr,pay)
		end

		def fields
			lenptr = FFI::MemoryPointer.new :int
			rv = Nmsg.nmsg_message_get_num_fields(@ptr, lenptr)
			len = lenptr.get_int(0)
			fields = []
			(0...len).each do |i|
				typeptr = FFI::MemoryPointer.new :int
				rv = Nmsg.nmsg_message_get_field_type_by_idx(@ptr,i, typeptr)
				type = typeptr.get_int(0)
				nameptr = FFI::MemoryPointer.new 255
				rv = Nmsg.nmsg_message_get_field_name(@ptr, i, nameptr)
				name = nameptr.get_pointer(0).get_string(0)
				nameptr.free
				fields << name
			end
			fields
		end

		def method_missing(name, *args)
			name = name.to_s
			typeptr = FFI::MemoryPointer.new :int
			rv = Nmsg.nmsg_message_get_field_type(@ptr, name, typeptr)
			type = typeptr.get_int(0)
			typeptr.free
			value = nil
			if rv == :success
				dataptr = FFI::MemoryPointer.new :pointer
				lenptr = FFI::MemoryPointer.new :int
				#nmsg_res nmsg_message_get_field(nmsg_message_t msg, const char *field_name, unsigned val_idx, void **data, size_t *len);
				rv = Nmsg.nmsg_message_get_field(@ptr, name, 0, dataptr, lenptr)
				if rv == :success
					if dataptr.get_pointer(0).null?
						value = nil
					elsif type == 4
						value = IPAddr.new_ntoh(dataptr.get_pointer(0).read_string(lenptr.get_int(0)))
					elsif type == 5
						value = dataptr.get_pointer(0).get_int(0)
					elsif type == 3
						value = dataptr.get_pointer(0).read_string(lenptr.get_int(0))
					elsif type == 0
						value = "ENUM:"+dataptr.get_pointer(0).get_int(0).to_s
					else
						value = dataptr.get_pointer(0).read_string(lenptr.get_int(0))
					end
				end
				dataptr.free
				lenptr.free
			end
			value
		end

		def to_hash
			lenptr = FFI::MemoryPointer.new :int
			rv = Nmsg.nmsg_message_get_num_fields(@ptr, lenptr)
			len = lenptr.get_int(0)
			lenptr.free
			h = {}
			(0...len).each do |i|
				typeptr = FFI::MemoryPointer.new :int
				rv = Nmsg.nmsg_message_get_field_type_by_idx(@ptr,i, typeptr)
				type = typeptr.get_int(0)
				typeptr.free
				nameptr = FFI::MemoryPointer.new 255
				rv = Nmsg.nmsg_message_get_field_name(@ptr, i, nameptr)
				name = nameptr.get_pointer(0).get_string(0)
				nameptr.free
				dataptr = FFI::MemoryPointer.new :pointer
				rv = Nmsg.nmsg_message_get_field_by_idx(@ptr, i, 0, dataptr, lenptr)
				if dataptr.get_pointer(0).null?
					h[name] = nil
				elsif type == 4
					h[name] = IPAddr.new_ntoh(dataptr.get_pointer(0).read_string(lenptr.get_int(0)))
				elsif type == 5
					h[name] = dataptr.get_pointer(0).get_int(0)
				elsif type == 3
					h[name] = dataptr.get_pointer(0).read_string(lenptr.get_int(0))
				elsif type == 0
					h[name] = "ENUM:"+dataptr.get_pointer(0).get_int(0).to_s
				else
					h[name] = dataptr.get_pointer(0).read_string(lenptr.get_int(0))
				end
				dataptr.free
			end
			h
		end
	end

	# <nmsg/message.h>
	# nmsg_message_t nmsg_message_init(nmsg_msgmod_t mod);
	attach_function :nmsg_message_init, :nmsg_message_init, [:pointer], :pointer
	# nmsg_message_t nmsg_message_from_raw_payload(unsigned vid, unsigned msgtype, uint8_t *data, size_t sz, const struct timespec *ts);
	attach_function :nmsg_message_from_raw_payload, :nmsg_message_from_raw_payload, [:int,:int,:pointer,:int,:pointer], :pointer
	# void nmsg_message_destroy(nmsg_message_t *msg);
	attach_function :nmsg_message_destroy, :nmsg_message_destroy, [:pointer], :void
	# nmsg_res nmsg_message_to_pres(nmsg_message_t msg, char **pres, const char *endline);
	attach_function :nmsg_message_to_pres, :nmsg_message_to_pres, [:pointer,:pointer,:string], Res
	# nmsg_msgmod_t nmsg_message_get_msgmod(nmsg_message_t msg);
	attach_function :nmsg_message_get_msgmod, :nmsg_message_get_msgmod, [:pointer], :pointer
	# nmsg_res nmsg_message_add_allocation(nmsg_message_t msg, void *ptr);
	attach_function :nmsg_message_add_allocation, :nmsg_message_add_allocation, [:pointer,:pointer], Res
	# void nmsg_message_free_allocations(nmsg_message_t msg);
	attach_function :nmsg_message_free_allocations, :nmsg_message_free_allocations, [:pointer], :void
	# int32_t nmsg_message_get_vid(nmsg_message_t msg);
	attach_function :nmsg_message_get_vid, :nmsg_message_get_vid, [:pointer], :int
	# int32_t nmsg_message_get_msgtype(nmsg_message_t msg);
	attach_function :nmsg_message_get_msgtype, :nmsg_message_get_msgtype, [:pointer], :int
	# void * nmsg_message_get_payload(nmsg_message_t msg);
	attach_function :nmsg_message_get_payload, :nmsg_message_get_payload, [:pointer], :pointer
	# void nmsg_message_update(nmsg_message_t msg);
	attach_function :nmsg_message_update, :nmsg_message_update, [:pointer], :void
	# void nmsg_message_compact_payload(nmsg_message_t msg);
	attach_function :nmsg_message_compact_payload, :nmsg_message_compact_payload, [:pointer], :void
	# void nmsg_message_get_time(nmsg_message_t msg, struct timespec *ts);
	attach_function :nmsg_message_get_time, :nmsg_message_get_time, [:pointer,:pointer], :void
	# void nmsg_message_set_time(nmsg_message_t msg, const struct timespec *ts);
	attach_function :nmsg_message_set_time, :nmsg_message_set_time, [:pointer,:pointer], :void
	# uint32_t nmsg_message_get_source(nmsg_message_t msg);
	attach_function :nmsg_message_get_source, :nmsg_message_get_source, [:pointer], :int
	# uint32_t nmsg_message_get_operator(nmsg_message_t msg);
	attach_function :nmsg_message_get_operator, :nmsg_message_get_operator, [:pointer], :int
	# uint32_t nmsg_message_get_group(nmsg_message_t msg);
	attach_function :nmsg_message_get_group, :nmsg_message_get_group, [:pointer], :int

	# void nmsg_message_set_source(nmsg_message_t msg, uint32_t source);
	attach_function :nmsg_message_set_source, :nmsg_message_set_source, [:pointer,:int], :void
	# void nmsg_message_set_operator(nmsg_message_t msg, uint32_t operator_);
	attach_function :nmsg_message_set_operator, :nmsg_message_set_operator, [:pointer,:int], :void
	# void nmsg_message_set_group(nmsg_message_t msg, uint32_t group);
	attach_function :nmsg_message_set_group, :nmsg_message_set_group, [:pointer,:int], :void
	# nmsg_res nmsg_message_get_field(nmsg_message_t msg, const char *field_name, unsigned val_idx, void **data, size_t *len);
	attach_function :nmsg_message_get_field, :nmsg_message_get_field, [:pointer,:string,:int,:pointer,:pointer], Res
	# nmsg_res nmsg_message_get_field_by_idx(nmsg_message_t msg, unsigned field_idx, unsigned val_idx, void **data, size_t *len);
	attach_function :nmsg_message_get_field_by_idx, :nmsg_message_get_field_by_idx, [:pointer,:int,:int,:pointer,:pointer], Res
	# nmsg_res nmsg_message_get_field_idx(nmsg_message_t msg, const char *field_name, unsigned *idx);
	attach_function :nmsg_message_get_field_idx, :nmsg_message_get_field_idx, [:pointer,:string,:pointer], Res
	# nmsg_res nmsg_message_get_field_name(nmsg_message_t msg, unsigned field_idx, const char **field_name);
	attach_function :nmsg_message_get_field_name, :nmsg_message_get_field_name, [:pointer,:int,:pointer], Res
	# nmsg_res nmsg_message_get_field_flags(nmsg_message_t msg, const char *field_name, unsigned *flags);
	attach_function :nmsg_message_get_field_flags, :nmsg_message_get_field_flags, [:pointer,:string,:pointer], Res
	# nmsg_res nmsg_message_get_field_flags_by_idx(nmsg_message_t msg, unsigned field_idx, unsigned *flags);
	attach_function :nmsg_message_get_field_flags_by_idx, :nmsg_message_get_field_flags_by_idx, [:pointer,:int,:pointer], Res
	# nmsg_res nmsg_message_get_field_type(nmsg_message_t msg, const char *field_name, nmsg_msgmod_field_type *type);
	attach_function :nmsg_message_get_field_type, :nmsg_message_get_field_type, [:pointer,:string,:pointer], Res
	# nmsg_res nmsg_message_get_field_type_by_idx(nmsg_message_t msg, unsigned field_idx, nmsg_msgmod_field_type *type);
	attach_function :nmsg_message_get_field_type_by_idx, :nmsg_message_get_field_type_by_idx, [:pointer,:int,:pointer], Res
	# nmsg_res nmsg_message_get_num_fields(nmsg_message_t msg, size_t *n_fields);
	attach_function :nmsg_message_get_num_fields, :nmsg_message_get_num_fields, [:pointer,:pointer], Res
	# nmsg_res nmsg_message_set_field(nmsg_message_t msg, const char *field_name, unsigned val_idx, const uint8_t *data, size_t len);
	attach_function :nmsg_message_set_field, :nmsg_message_set_field, [:pointer,:string,:int,:pointer,:int], Res
	# nmsg_res nmsg_message_set_field_by_idx(nmsg_message_t msg, unsigned field_idx, unsigned val_idx, const uint8_t *data, size_t len);
	attach_function :nmsg_message_set_field_by_idx, :nmsg_message_set_field_by_idx, [:pointer,:int,:int,:pointer,:int], Res
	# nmsg_res nmsg_message_enum_name_to_value(nmsg_message_t msg, const char *field_name, const char *name, unsigned *value);
	attach_function :nmsg_message_enum_name_to_value, :nmsg_message_enum_name_to_value, [:pointer,:string,:string,:pointer], Res
	# nmsg_res nmsg_message_enum_name_to_value_by_idx(nmsg_message_t msg, unsigned field_idx, const char *name, unsigned *value);
	attach_function :nmsg_message_enum_name_to_value_by_idx, :nmsg_message_enum_name_to_value_by_idx, [:pointer,:int,:string,:pointer], Res
	# nmsg_res nmsg_message_enum_value_to_name(nmsg_message_t msg, const char *field_name, unsigned value, const char **name);
	attach_function :nmsg_message_enum_value_to_name, :nmsg_message_enum_value_to_name, [:pointer,:string,:int,:pointer], Res
	# nmsg_res nmsg_message_enum_value_to_name_by_idx(nmsg_message_t msg, unsigned field_idx, unsigned value, const char **name);
	attach_function :nmsg_message_enum_value_to_name_by_idx, :nmsg_message_enum_value_to_name_by_idx, [:pointer,:int,:int,:pointer], Res
end
