require 'pp'

module Nmsg
	module Output
		class Output
			def flush
				Nmsg.nmsg_output_flush(@output)
			end

			def ptr
				@output
			end

			def write(msg)
				Nmsg.nmsg_output_write(@output,msg.ptr)
			end

			def close
				ptr = FFI::MemoryPointer.new :pointer
				ptr.put_pointer(0,@output)
				Nmsg.nmsg_output_close(ptr)
			end

			def buffered=(bufbool)
				Nmsg.nmsg_output_set_buffered(@output,bufbool)
			end

			def filter(opts={})
				if opts[:vid] and opts[:msgtype]
					if opts[:vid].is_a? String
						Nmsg.nmsg_output_set_filter_msgtype_byname(@output, opts[:vid], opts[:msgtype])
					else
						Nmsg.nmsg_output_set_filter_msgtype(@output, opts[:vid], opts[:msgtype])
					end
				else
					Nmsg.nmsg_output_set_filter_msgtype(@output, 0, 0)
				end
			end

			def rate=(rate)
				freq = rate/10
				rate = Nmsg.nmsg_rate_init(rate,freq)
				Nmsg.nmsg_output_set_rate(@output,rate)
			end

			def endline=(endl)
				Nmsg.nmsg_output_set_endline(@output,endl)
			end

			def source=(source)
				Nmsg.nmsg_output_set_source(@output,source)
			end

			def operator=(operator)
				Nmsg.nmsg_output_set_operator(@output,operator)
			end

			def group=(group)
				Nmsg.nmsg_output_set_group(@output,group)
			end

			def gzipped=(bool)
				Nmsg.nmsg_output_set_zlibout(@output,bool)
			end
		end

		class File < Output
			def initialize(file)
				if file.is_a? String
					file = ::File.open(file,'w')
				elsif file.is_a? File
				else
					raise "Unknown object type for #{self.class}.new, #{file.class}"
				end
				@output = Nmsg.nmsg_output_open_file(file.fileno)
			end
		end

		class Socket < Output
			def initialize(port,host='')
				sock = UDPSocket.new
				sock.bind(host,port)
				@output = Nmsg.nmsg_output_open_sock(sock.fileno)
			end
		end

		class Pres < Output
			def initialize(file)
				if file.is_a? String
					file = ::File.open(file,'w')
				elsif file.is_a? File
				else
					raise "Unknown object type for #{self.class}.new, #{file.class}"
				end
				@output = Nmsg.nmsg_output_open_pres(file.fileno)
			end

			def flush
				true
			end
		end
		
		class Callback < Output
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
			
			
			def initialize(cb=nil, user=nil, &block)
				f = _wrap_callback(cb,block)
				@output = Nmsg.nmsg_output_open_callback(f, user)
			end
		end
	end

	# <nmsg/output.h>
	# nmsg_output_t nmsg_output_open_file(int fd, size_t bufsz);
	attach_function :nmsg_output_open_file, :nmsg_output_open_file, [:int,:int], :pointer
	# nmsg_output_t nmsg_output_open_sock(int fd, size_t bufsz);
	attach_function :nmsg_output_open_sock, :nmsg_output_open_sock, [:int,:int], :pointer
	# nmsg_output_t nmsg_output_open_pres(int fd);
	attach_function :nmsg_output_open_pres, :nmsg_output_open_pres, [:int], :pointer
	# nmsg_output_t nmsg_output_open_callback(nmsg_cb_message cb, void *user);
	attach_function :nmsg_output_open_callback, :nmsg_output_open_callback, [:nmsg_cb_message,:pointer], :pointer
	# nmsg_res nmsg_output_flush(nmsg_output_t output);
	attach_function :nmsg_output_flush, :nmsg_output_flush, [:pointer], :int
	# nmsg_res nmsg_output_write(nmsg_output_t output, nmsg_message_t msg);
	attach_function :nmsg_output_write, :nmsg_output_write, [:pointer,:pointer], :int
	# nmsg_res nmsg_output_close(nmsg_output_t *output);
	attach_function :nmsg_output_close, :nmsg_output_close, [:pointer], :int
	# void nmsg_output_set_buffered(nmsg_output_t output, bool buffered);
	attach_function :nmsg_output_set_buffered, :nmsg_output_set_buffered, [:pointer,:bool], :void
	# void nmsg_output_set_filter_msgtype(nmsg_output_t output, unsigned vid, unsigned msgtype);
	attach_function :nmsg_output_set_filter_msgtype, :nmsg_output_set_filter_msgtype, [:pointer,:int,:int], :void
	# nmsg_res nmsg_output_set_filter_msgtype_byname(nmsg_output_t output, const char *vname, const char *mname);
	attach_function :nmsg_output_set_filter_msgtype_byname, :nmsg_output_set_filter_msgtype_byname, [:pointer,:string,:string], :int
	# void nmsg_output_set_rate(nmsg_output_t output, nmsg_rate_t rate);
	attach_function :nmsg_output_set_rate, :nmsg_output_set_rate, [:pointer,:pointer], :void
	# void nmsg_output_set_endline(nmsg_output_t output, const char *endline);
	attach_function :nmsg_output_set_endline, :nmsg_output_set_endline, [:pointer,:string], :void
	# void nmsg_output_set_source(nmsg_output_t output, unsigned source);
	attach_function :nmsg_output_set_source, :nmsg_output_set_source, [:pointer,:int], :void
	# void nmsg_output_set_operator(nmsg_output_t output, unsigned operator_);
	attach_function :nmsg_output_set_operator, :nmsg_output_set_operator, [:pointer,:int], :void
	# void nmsg_output_set_group(nmsg_output_t output, unsigned group);
	attach_function :nmsg_output_set_group, :nmsg_output_set_group, [:pointer,:int], :void
	# void nmsg_output_set_zlibout(nmsg_output_t output, bool zlibout);
	attach_function :nmsg_output_set_zlibout, :nmsg_output_set_zlibout, [:pointer,:bool], :void
end

