module Nmsg
	class CloseEventInOutU < FFI::Union
		layout :input, :pointer,
		:output, :pointer
	end
	
	class CloseEventInOutTypeU < FFI::Union
		layout :input_type, :int,
		:output_type, :int
	end
	
	class CloseEvent < FFI::Struct
		layout :inout, CloseEventInOutU,
		:inout_type, CloseEventInOutTypeU,
		:io, :pointer,
		:io_type, :int,
		:close_type, :int,
		:user, :pointer
	end
	
	class IO
		def initialize
			@io = Nmsg.nmsg_io_init()
		end

		def add_input(input, user=nil)
			Nmsg.nmsg_io_add_input(@io,input.ptr,user)
		end

		def add_input_channel(channel, user=nil)
			Nmsg.nmsg_io_add_input_channel(@io,channel, user)
		end

		def add_input_sockspec(sockspec, user=nil)
			if sockspec =~ /^((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|([a-fA-f0-9:]+))\/\d{1,5}(\.\.\d{1,5})?/
				Nmsg.nmsg_io_add_input_sockspec(@io,sockspec,user)
			else
				raise ArgumentError "Sockspec should be <IP>/<PORT> or <IP>/<start PORT>..<end PORT>"
			end
		end

		def add_input_fname(fname, user=nil)
			Nmsg.nmsg_io_add_input_fname(@io,fname,user)
		end

		def add_output(output, user=nil)
			Nmsg.nmsg_io_add_output(@io,output.ptr,user)
		end

		def loop
			raise "Nmsg::IO.loop causes Ruby to hang"
			Nmsg.nmsg_io_loop(@io)
		end

		def breakloop
			Nmsg.nmsg_io_breakloop(@io)
		end

		def destroy
			ptr = FFI::MemoryPointer.new :pointer
			ptr.put_pointer(0,@io)
			Nmsg.nmsg_io_destroy(ptr)
		end

		def input_count
			Nmsg.nmsg_io_get_num_inputs(@io)
		end

		def output_count
			Nmsg.nmsg_io_get_num_outputs(@io)
		end

		def _wrap_close_callback(h, block)
			h ||= @handler

			if h
				h = h.new() if h.kind_of?(Class)

				unless h.respond_to?(:close_fp)
					raise(NoMethodError, "The handler #{h.class} has no close_fp method",caller)
				end

				return lambda { |close_event| 
					yld = h.close_fp(self, CloseEvent.new(close_event))
					block.call(*yld) if (block && yld)
				}
			elsif (block.kind_of?(Proc) || block.kind_of?(Method))
				return lambda { |close_event|
					block.call(CloseEvent.new(close_event))
				}
			else
				raise(ArgumentError,"Neither a handler nor block were provided",caller)
			end
		end

		def _wrap_user_callback(h, block)
			h ||= @handler

			if h
				h = h.new() if h.kind_of?(Class)

				unless h.respond_to?(:call)
					raise(NoMethodError, "The handler #{h.class} has no call method",caller)
				end

				return lambda { |thread_no, user| 
					yld = h.call(self, thread_no, user)
					block.call(*yld) if (block && yld)
				}
			elsif (block.kind_of?(Proc) || block.kind_of?(Method))
				return lambda { |thread_no, user|
					block.call(thread_no, user)
				}
			else
				raise(ArgumentError,"Neither a handler nor block were provided",caller)
			end
		end

		def close_fp(fp=nil, &block)
			f = _wrap_close_callback(fp,block)
			Nmsg.nmsg_io_set_close_fp(@io,f)
		end
		alias :close_cb :close_fp

		def atstart_fp(fp=nil, user=nil, &block)
			f = _wrap_user_callback(fp,block)
			Nmsg.nmsg_io_set_atstart_fp(@io,f,user)
		end
		alias :start_cb :atstart_fp

		def atexit_fp(fp=nil, user=nil, &block)
			f = _wrap_user_callback(fp,block)
			Nmsg.nmsg_io_set_atexit_fp(@io,f,user)
		end
		alias :exit_cb :atexit_fp

		def count=(count)
			Nmsg.nmsg_io_set_count(@io,count)
		end

		def debug=(debug)
			Nmsg.nmsg_io_set_debuf(@io,debug)
		end

		def interval=(interval)
			Nmsg.nmsg_io_set_interval(@io,interval)
		end

		def output_mode=(mode)
			Nmsg.nmsg_io_set_output_mode(@io,mode)
		end
	end

	# <nmsg/io.h>
	# nmsg_io_t nmsg_io_init(void);
	attach_function :nmsg_io_init, :nmsg_io_init, [], :pointer
	# nmsg_res nmsg_io_add_input(nmsg_io_t io, nmsg_input_t input, void *user);
	attach_function :nmsg_io_add_input, :nmsg_io_add_input, [:pointer,:pointer,:pointer], Res
	# nmsg_res nmsg_io_add_input_channel(nmsg_io_t io, const char *chan, void *user);
	attach_function :nmsg_io_add_input_channel, :nmsg_io_add_input_channel, [:pointer,:string,:pointer], Res
	# nmsg_res nmsg_io_add_input_sockspec(nmsg_io_t io, const char *sockspec, void *user);
	attach_function :nmsg_io_add_input_sockspec, :nmsg_io_add_input_sockspec, [:pointer,:string,:pointer], Res
	# nmsg_res nmsg_io_add_input_fname(nmsg_io_t io, const char *fname, void *user);
	attach_function :nmsg_io_add_input_fname, :nmsg_io_add_input_fname, [:pointer,:string,:pointer], Res
	# nmsg_res nmsg_io_add_output(nmsg_io_t io, nmsg_output_t output, void *user);
	attach_function :nmsg_io_add_output, :nmsg_io_add_output, [:pointer,:pointer,:pointer], Res
	# nmsg_res nmsg_io_loop(nmsg_io_t io);
	attach_function :nmsg_io_loop, :nmsg_io_loop, [:pointer], Res
	# void nmsg_io_breakloop(nmsg_io_t io);
	attach_function :nmsg_io_breakloop, :nmsg_io_breakloop, [:pointer], :void
	# void nmsg_io_destroy(nmsg_io_t *io);
	attach_function :nmsg_io_destroy, :nmsg_io_destroy, [:pointer], :void
	# unsigned nmsg_io_get_num_inputs(nmsg_io_t io);
	attach_function :nmsg_io_get_num_inputs, :nmsg_io_get_num_inputs, [:pointer], :int
	# unsigned nmsg_io_get_num_outputs(nmsg_io_t io);
	attach_function :nmsg_io_get_num_outputs, :nmsg_io_get_num_outputs, [:pointer], :int
	# void nmsg_io_set_close_fp(nmsg_io_t io, nmsg_io_close_fp close_fp);
	attach_function :nmsg_io_set_close_fp, :nmsg_io_set_close_fp, [:pointer,:nmsg_io_close_fp], :void
	# void nmsg_io_set_atstart_fp(nmsg_io_t io, nmsg_io_user_fp user_fp, void *user);
	attach_function :nmsg_io_set_atstart_fp, :nmsg_io_set_atstart_fp, [:pointer,:nmsg_io_user_fp,:pointer], :void
	# void nmsg_io_set_atexit_fp(nmsg_io_t io, nmsg_io_user_fp user_fp, void *user);
	attach_function :nmsg_io_set_atexit_fp, :nmsg_io_set_atexit_fp, [:pointer,:nmsg_io_user_fp,:pointer], :void
	# void nmsg_io_set_count(nmsg_io_t io, unsigned count);
	attach_function :nmsg_io_set_count, :nmsg_io_set_count, [:pointer,:int], :void
	# void nmsg_io_set_debug(nmsg_io_t io, int debug);
	attach_function :nmsg_io_set_debug, :nmsg_io_set_debug, [:pointer,:int], :void
	# void nmsg_io_set_interval(nmsg_io_t io, unsigned interval);
	attach_function :nmsg_io_set_interval, :nmsg_io_set_interval, [:pointer,:int], :void
	# void nmsg_io_set_output_mode(nmsg_io_t io, nmsg_io_output_mode output_mode);
	attach_function :nmsg_io_set_output_mode, :nmsg_io_set_output_mode, [:pointer,:int], :void
end