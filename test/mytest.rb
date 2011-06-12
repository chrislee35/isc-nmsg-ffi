require 'ffi'
module Nmsg
	extend FFI::Library
	ffi_lib 'nmsg'
	
	callback :nmsg_cb_message, [:pointer, :pointer], :void

	# nmsg_res nmsg_init(void);
	attach_function :nmsg_init, :nmsg_init, [], :int
	# nmsg_input_t nmsg_input_open_file(int fd);
	attach_function :nmsg_input_open_file, :nmsg_input_open_file, [:int], :pointer
	# nmsg_output_t nmsg_output_open_callback(nmsg_cb_message cb, void *user);
	attach_function :nmsg_output_open_callback, :nmsg_output_open_callback, [:nmsg_cb_message,:pointer], :pointer
	# nmsg_io_t nmsg_io_init(void);
	attach_function :nmsg_io_init, :nmsg_io_init, [], :pointer
	# nmsg_res nmsg_io_add_input(nmsg_io_t io, nmsg_input_t input, void *user);
	attach_function :nmsg_io_add_input, :nmsg_io_add_input, [:pointer,:pointer,:pointer], :int
	# nmsg_res nmsg_io_add_output(nmsg_io_t io, nmsg_output_t output, void *user);
	attach_function :nmsg_io_add_output, :nmsg_io_add_output, [:pointer,:pointer,:pointer], :int
	# nmsg_res nmsg_io_loop(nmsg_io_t io);
	attach_function :nmsg_io_loop, :nmsg_io_loop, [:pointer], :int
	# void nmsg_io_destroy(nmsg_io_t *io);
	attach_function :nmsg_io_destroy, :nmsg_io_destroy, [:pointer], :void
end

res = Nmsg.nmsg_init
io = Nmsg.nmsg_io_init
f = File.new("test.nmsg")
input = Nmsg.nmsg_input_open_file(f.fileno)
res = Nmsg.nmsg_io_add_input(io, input, nil)
callback = lambda { |msg,usr|
	puts msg
}
output = Nmsg.nmsg_output_open_callback(callback, nil)
res = Nmsg.nmsg_io_add_output(io, output, nil)
res = Nmsg.nmsg_io_loop(io) # this will not work in Ruby 1.8.7 and Ruby 1.9.2p180
ptr = FFI::MemoryPointer.new :pointer
ptr.set_pointer(0,io)
Nmsg.nmsg_io_destroy(ptr)
