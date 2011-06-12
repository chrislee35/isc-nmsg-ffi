require 'ffi'

module Nmsg
	extend FFI::Library
	ffi_lib 'nmsg'

	callback :nmsg_cb_message, [:pointer, :pointer], :void
	callback :nmsg_io_close_fp, [:pointer], :void
	callback :nmsg_io_user_fp, [:int,:pointer], :void

	Res = enum(
		:success,
		:failure,
		:eof,
		:memfail,
		:magic_mismatch,
		:version_mismatch,
		:pbuf_ready,
		:notimpl,
		:stop,
		:again,
		:parse_error,
		:pcap_error,
		:read_failure
	)
	
	# <nmsg.h>
	# nmsg_res nmsg_init(void);
	attach_function :nmsg_init, :nmsg_init, [], Res
	# void nmsg_set_autoclose(bool autoclose);
	attach_function :nmsg_set_autoclose, :nmsg_set_autoclose, [:bool], :void
	# void nmsg_set_debug(int debug);
	attach_function :nmsg_set_debug, :nmsg_set_debug, [:int], :void

	# <nmsg/timespec.h>
	# void nmsg_timespec_get(struct timespec *ts);
	attach_function :nmsg_timespec_get, :nmsg_timespec_get, [:pointer], :void
	# void nmsg_timespec_sleep(const struct timespec *ts);
	attach_function :nmsg_timespec_sleep, :nmsg_timespec_sleep, [:pointer], :void
	# void nmsg_timespec_sub(const struct timespec *a, struct timespec *b);
	attach_function :nmsg_timespec_sub, :nmsg_timespec_sub, [:pointer,:pointer], :void
	# double nmsg_timespec_to_double(const struct timespec *ts);
	attach_function :nmsg_timespec_to_double, :nmsg_timespec_to_double, [:pointer], :double

	# <nmsg/rate.h>
	# nmsg_rate_t nmsg_rate_init(unsigned rate, unsigned freq);
	attach_function :nmsg_rate_init, :nmsg_rate_init, [:int,:int], :pointer
	# void nmsg_rate_destroy(nmsg_rate_t *r);
	attach_function :nmsg_rate_destroy, :nmsg_rate_destroy, [:pointer], :void
	# void nmsg_rate_sleep(nmsg_rate_t r);
	attach_function :nmsg_rate_sleep, :nmsg_rate_sleep, [:pointer], :void

	Nmsg.nmsg_init
end