module Nmsg
	class Msgmod
		attr_reader :vid, :vname, :msgtype, :mname, :ptr
		def initialize(vid,msgtype)
			if vid.is_a? String
				@vname = vid
				@vid = Msgmod.vname_to_vid(vid)
				if @vid == 0
					raise ArgumentError "Unknown vendor name: #{vid}"
				end
			elsif vid.is_a? Numeric
				@vid = vid
				@vname = Msgmod.vid_to_vname(vid)
				unless @vname
					raise ArgumentError "Unknown vendor id: #{vid}"
				end
			else
				raise ArgumentError "the vid must be a string or a numeric"
			end

			if msgtype.is_a? String
				@mname = msgtype
				@msgtype = Msgmod.mname_to_msgtype(@vid,msgtype)
				if @msgtype == 0
					raise ArgumentError "Unknown message type: #{msgtype}"
				end
			elsif msgtype.is_a? Numeric
				@msgtype = msgtype
				@mname = Msgmod.msgtype_to_mname(@vid,msgtype)
				unless @mname
					raise ArgumentError "Unknown message id: #{msgtype}"
				end
			else
				raise ArgumentError "the msgtype must be a string or a numeric"
			end
			@ptr = Nmsg.nmsg_msgmod_lookup(@vid,@msgtype)
			unless @ptr
				raise ArgumentError "Could not look up the message module from the given vendor and msgtype"
			end
			@clos = FFI::MemoryPointer.new :pointer
			Nmsg.nmsg_msgmod_init(@ptr,@clos)
		end

		def fini
			Nmsg.nmsg_msgmod_fini(@ptr,@clos)
		end

		def pres_to_payload(pres)
			Nmsg.nmsg_msgmod_pres_to_payload(@ptr,@clos.get_pointer(0),pres)
		end

		def pres_to_payload_finalize
			buf = FFI::MemoryPointer.new(1048576)
			sz = FFI::MemoryPointer.new :int
			Nmsg.nmsg_msgmod_pres_to_payload_finalize(@ptr,@clos.get_pointer(0),buf,sz)
			buf.get_string(sz.get_int(0))
		end

		def ipdg_to_payload(ipdg)
			raise "Not implemented"
		end

		def pkt_to_payload(pkt)
			raise "Not implemented"
		end

		def Msgmod::mname_to_msgtype(vid,mname)
			return nil unless vid and mname
			Nmsg.nmsg_msgmod_mname_to_msgtype(vid,mname)
		end

		def Msgmod::msgtype_to_mname(vid,msgtype)
			Nmsg.nmsg_msgmod_msgtype_to_mname(vid,msgtype)
		end

		def Msgmod::vid_to_vname(vid)
			Nmsg.nmsg_msgmod_vid_to_vname(vid)
		end

		def Msgmod::vname_to_vid(vidname)
			return nil unless vidname
			Nmsg.nmsg_msgmod_vname_to_vid(vidname)
		end

		def Msgmod::max_vid
			Nmsg.nmsg_msgmod_get_max_vid
		end

		def Msgmod::max_msgtype(vid)
			Nmsg.nmsg_msgmod_get_max_msgtype(vid)
		end
	end


	# nmsg_res nmsg_msgmod_init(nmsg_msgmod_t mod, void **clos);
	attach_function :nmsg_msgmod_init, :nmsg_msgmod_init, [:pointer,:pointer], :int
	# nmsg_res nmsg_msgmod_fini(nmsg_msgmod_t mod, void **clos);
	attach_function :nmsg_msgmod_fini, :nmsg_msgmod_fini, [:pointer,:pointer], :int
	# nmsg_res nmsg_msgmod_pres_to_payload(nmsg_msgmod_t mod, void *clos, const char *pres);
	attach_function :nmsg_msgmod_pres_to_payload, :nmsg_msgmod_pres_to_payload, [:pointer,:pointer,:string], :int
	# nmsg_res nmsg_msgmod_pres_to_payload_finalize(nmsg_msgmod_t mod, void *clos, uint8_t **pbuf, size_t *sz);
	attach_function :nmsg_msgmod_pres_to_payload_finalize, :nmsg_msgmod_pres_to_payload_finalize, [:pointer,:pointer,:pointer,:pointer], :int
	# nmsg_res nmsg_msgmod_ipdg_to_payload(nmsg_msgmod_t mod, void *clos, const struct nmsg_ipdg *dg, uint8_t **pbuf, size_t *sz);
	attach_function :nmsg_msgmod_ipdg_to_payload, :nmsg_msgmod_ipdg_to_payload, [:pointer,:pointer,:pointer,:pointer,:pointer], :int
	# nmsg_res nmsg_msgmod_pkt_to_payload(struct nmsg_msgmod *mod, void *clos, nmsg_pcap_t pcap, nmsg_message_t *m);
	attach_function :nmsg_msgmod_pkt_to_payload, :nmsg_msgmod_pkt_to_payload, [:pointer,:pointer,:pointer,:pointer], :int

	# nmsg_msgmod_t nmsg_msgmod_lookup(unsigned vid, unsigned msgtype);
	attach_function :nmsg_msgmod_lookup, :nmsg_msgmod_lookup, [:int,:int], :pointer
	# nmsg_msgmod_t nmsg_msgmod_lookup_byname(const char *vname, const char *mname);
	attach_function :nmsg_msgmod_lookup_byname, :nmsg_msgmod_lookup_byname, [:string,:string], :pointer

	# unsigned nmsg_msgmod_mname_to_msgtype(unsigned vid, const char *mname);
	attach_function :nmsg_msgmod_mname_to_msgtype, :nmsg_msgmod_mname_to_msgtype, [:int,:string], :int
	# const char * nmsg_msgmod_msgtype_to_mname(unsigned vid, unsigned msgtype);
	attach_function :nmsg_msgmod_msgtype_to_mname, :nmsg_msgmod_msgtype_to_mname, [:int,:int], :string
	# const char * nmsg_msgmod_vid_to_vname(unsigned vid);
	attach_function :nmsg_msgmod_vid_to_vname, :nmsg_msgmod_vid_to_vname, [:int], :string
	# unsigned nmsg_msgmod_vname_to_vid(const char *vname);
	attach_function :nmsg_msgmod_vname_to_vid, :nmsg_msgmod_vname_to_vid, [:string], :int
	# unsigned nmsg_msgmod_get_max_vid(void);
	attach_function :nmsg_msgmod_get_max_vid, :nmsg_msgmod_get_max_vid, [], :int
	# unsigned nmsg_msgmod_get_max_msgtype(unsigned vid);
	attach_function :nmsg_msgmod_get_max_msgtype, :nmsg_msgmod_get_max_msgtype, [:int], :int
end