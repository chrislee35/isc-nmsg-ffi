module Nmsg
	module Input
		class Input
			DEFAULT_COUNT = -1
			def close
				rv = Nmsg.nmsg_input_close(@input)
			end

			def ptr
				@input
			end

			def read
				msgptr = FFI::MemoryPointer.new :pointer
				rv = Nmsg.nmsg_input_read(@input, msgptr)
				Nmsg::Message.new(msgptr.get_pointer(0))
			end

			def loop(opts={}, &block)
				cnt = (opts[:count] || DEFAULT_COUNT)
				h = opts[:handler]
				usr = opts[:usr]
				rv = Nmsg.nmsg_input_loop(@input, cnt, _wrap_callback(h, block), usr)
			end

			def _wrap_callback(h, block)
				h ||= @handler

				if h
					h = h.new() if h.kind_of?(Class)

					unless h.respond_to?(:receive_nmsg)
						raise(NoMethodError, "The handler #{h.class} has no receive_nmsg method",caller)
					end

					return lambda { |msg,usr| 
						yld = h.receive_nmsg(self, Nmsg::Message.new(msg), usr)
						block.call(*yld) if (block && yld)
					}
				elsif (block.kind_of?(Proc) || block.kind_of?(Method))
					return lambda { |msg,usr|
						block.call(Nmsg::Message.new(msg),usr)
					}
				else
					raise(ArgumentError,"Neither a handler nor block were provided",caller)
				end
			end

			def filter(opts={})
				if opts[:vid] and opts[:msgtype]
					if opts[:vid].is_a? String
						Nmsg.nmsg_input_set_filter_msgtype_byname(@input, opts[:vid], opts[:msgtype])
					else
						Nmsg.nmsg_input_set_filter_msgtype(@input, opts[:vid], opts[:msgtype])
					end
				else
					Nmsg.nmsg_input_set_filter_msgtype(@input, 0, 0)
				end
				if opts[:source]
					Nmsg.nmsg_input_set_filter_source(@input, opts[:source])
				else
					Nmsg.nmsg_input_set_filter_source(@input, 0)
				end
				if opts[:operator]
					Nmsg.nmsg_input_set_filter_operator(@input, opts[:operator])
				else
					Nmsg.nmsg_input_set_filter_operator(@input, 0)
				end
				if opts[:group]
					Nmsg.nmsg_input_set_filter_group(@input, opts[:group])
				else
					Nmsg.nmsg_input_set_filter_group(@input, 0)
				end
			end
		end

		class Socket < Input
			def initialize(port,host='')
				@sock = UDPSocket.new
				@sock.bind(host,port)
				@input = Nmsg.nmsg_input_open_sock(@sock.fileno)
			end
		end

		class Channel < Input
			def initialize(channel)
			end
		end

		class File < Input
			def initialize(file)
				if file.is_a? String
					file = ::File.open(file)
				elsif file.is_a? File
				else
					raise "Unknown object type for #{self.class}.new, #{file.class}"
				end
				@input = Nmsg.nmsg_input_open_file(file.fileno)
			end
		end

		class Pres < Input
			def initialize(file, msgmod)
				if file.is_a? String
					file = ::File.open(file)
				elsif file.is_a? File
				else
					raise "Unknown object type for #{self.class}.new, #{file.class}"
				end
				@input = Nmsg.nmsg_input_open_pres(file.fileno, msgmod)
			end
		end

		class Pcap < Input
			def initialize(file, msgmod)
				if file.is_a? String
					file = ::File.open(file)
				elsif file.is_a? File
				else
					raise "Unknown object type for #{self.class}.new, #{file.class}"
				end
				@input = Nmsg.nmsg_input_open_pcap(file.fileno, msgmod)
			end
		end
	end

	# <nmsg/input.h>
	# nmsg_input_t nmsg_input_open_file(int fd);
	attach_function :nmsg_input_open_file, :nmsg_input_open_file, [:int], :pointer
	# nmsg_input_t nmsg_input_open_sock(int fd);
	attach_function :nmsg_input_open_sock, :nmsg_input_open_sock, [:int], :pointer
	# nmsg_input_t nmsg_input_open_pres(int fd, nmsg_msgmod_t msgmod);
	attach_function :nmsg_input_open_pres, :nmsg_input_open_pres, [:int,:pointer], :pointer
	# nmsg_input_t nmsg_input_open_pcap(nmsg_pcap_t pcap, nmsg_msgmod_t msgmod);
	attach_function :nmsg_input_open_pcap, :nmsg_input_open_pcap, [:pointer,:pointer], :pointer
	# nmsg_res nmsg_input_close(nmsg_input_t *input);
	attach_function :nmsg_input_close, :nmsg_input_close, [:pointer], :int
	# nmsg_res nmsg_input_loop(nmsg_input_t input, int count, nmsg_cb_message cb, void *user);
	attach_function :nmsg_input_loop, :nmsg_input_loop, [:pointer,:int,:nmsg_cb_message,:pointer], :int
	# nmsg_res nmsg_input_read(nmsg_input_t input, nmsg_message_t *msg);
	attach_function :nmsg_input_read, :nmsg_input_read, [:pointer,:pointer], :int
	# void nmsg_input_set_filter_msgtype(nmsg_input_t input, unsigned vid, unsigned msgtype);
	attach_function :nmsg_input_set_filter_msgtype, :nmsg_input_set_filter_msgtype, [:pointer,:int,:int], :void
	# nmsg_res nmsg_input_set_filter_msgtype_byname(nmsg_input_t input, const char *vname, const char *mname);
	attach_function :nmsg_input_set_filter_msgtype_byname, :nmsg_input_set_filter_msgtype_byname, [:pointer,:string,:string], Res
	# void nmsg_input_set_filter_source(nmsg_input_t input, unsigned source);
	attach_function :nmsg_input_set_filter_source, :nmsg_input_set_filter_source, [:pointer,:int], :void
	# void nmsg_input_set_filter_operator(nmsg_input_t input, unsigned operator_);
	attach_function :nmsg_input_set_filter_operator, :nmsg_input_set_filter_operator, [:pointer,:int], :void
	# void nmsg_input_set_filter_group(nmsg_input_t input, unsigned group);
	attach_function :nmsg_input_set_filter_group, :nmsg_input_set_filter_group, [:pointer,:int], :void
	# nmsg_res nmsg_input_set_blocking_io(nmsg_input_t input, bool flag);
	attach_function :nmsg_input_set_blocking_io, :nmsg_input_set_blocking_io, [:pointer,:bool], Res
end