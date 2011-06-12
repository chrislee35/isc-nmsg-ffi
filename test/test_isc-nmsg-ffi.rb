require 'helper'
require 'pp'

class TestIscNmsgFfi < Test::Unit::TestCase
	should "open an nmsg file and display the first packet" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		msg = input.read
		assert_equal("GET /search?q=0 HTTP/1.0\r\nUser-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; MEGAUPLOAD 1.0)\r\nHost: 149.20.56.34\r\nPragma: no-cache\r\n\r\n\000", msg.to_hash['request'])
		assert_equal("149.20.56.34", msg.dstip.to_s)
		assert_equal(["dstip", "dstport", "p0f_detail", "p0f_dist", "p0f_fw", "p0f_genre", "p0f_link", "p0f_mflags", "p0f_nat", "p0f_real", "p0f_score", "p0f_tos", "p0f_uptime", "request", "srchost", "srcip", "srcport", "type"], msg.fields)
	end

	should "open an nmsg file and call a callback on all packets" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		class MyCallback
			attr_reader :count
			def initialize
				@count = 0
			end
			def receive_nmsg(cls,msg,usr)
				@count += 1
			end
		end
		mcb = MyCallback.new
		input.loop :handler => mcb
		assert_equal(40,mcb.count)
	end

	should "open an nmsg file and call a block on all packets" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		count = 0
		input.loop do |msg, usr|
			count += 1
		end
		assert_equal(40,count)
	end

	should "open an nmsg file and call a block on 10 packets" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		count = 0
		input.loop :count => 10 do |msg, usr|
			count += 1
		end
		assert_equal(10,count)
	end

	should "open an nmsg file, set a filter, and call a block on all packets" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		input.filter({:vid=>1, :msgtype=>4})
		count = 0
		input.loop do |msg, usr|
			count += 1
		end
		assert_equal(40,count)
	end

	should "open an nmsg file, set a filter, and call a block on all packets (and receive none)" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		input.filter({:vid=>1, :msgtype=>5})
		count = 0
		input.loop do |msg, usr|
			count += 1
		end
		assert_equal(0,count)
	end

	should "lookup the vendor name and message types" do
		vendors = {}
		max_vid = Nmsg::Msgmod.max_vid
		assert_equal(1, max_vid)
		(1..max_vid).each do |vid|
			vname = Nmsg::Msgmod.vid_to_vname(vid)
			vid2 = Nmsg::Msgmod.vname_to_vid(vname)
			max_msgtype = Nmsg::Msgmod.max_msgtype(vid2)
			vendors[vname] = { :vid => vid, :vid2 => vid2, :max_msgtype => max_msgtype, :msgtypes => [] }
			(1..max_msgtype).each do |msgtype|
				mname = Nmsg::Msgmod.msgtype_to_mname(vid,msgtype)
				msgtype2 = Nmsg::Msgmod.mname_to_msgtype(vid,mname)
				vendors[vname][:msgtypes] << [msgtype, mname, msgtype2]
			end
		end
		assert_equal({"ISC"=>
			{:vid2=>1,
				:max_msgtype=>11,
				:vid=>1,
				:msgtypes=>
				[[1, "ncap", 1],
				[2, "email", 2],
				[3, "linkpair", 3],
				[4, "http", 4],
				[5, "ipconn", 5],
				[6, "logline", 6],
				[7, "dns", 7],
				[8, "pkt", 8],
				[9, "dnsqr", 9],
				[10, "xml", 10],
				[11, "encode", 11]]}}, vendors)
	end

	should "create message modules from vendor/message ids" do
		msgmod = Nmsg::Msgmod.new(1,10) #ISC/XML
		assert_not_nil(msgmod)
		assert_equal(1, msgmod.vid)
		assert_equal("ISC", msgmod.vname)
		assert_equal(10, msgmod.msgtype)
		assert_equal("xml", msgmod.mname)
	end

	should "create message modules from vendor/message names" do
		msgmod = Nmsg::Msgmod.new("ISC","xml") #1/10
		assert_not_nil(msgmod)
		assert_equal(1, msgmod.vid)
		assert_equal("ISC", msgmod.vname)
		assert_equal(10, msgmod.msgtype)
		assert_equal("xml", msgmod.mname)
	end
	
	should "convert an HTTP presentation to payload" do
		msgmod = Nmsg::Msgmod.new("ISC", "http")
		assert_not_nil(msgmod)
		pres = "[208] [2011-05-30 23:59:59.976026699] [1:4 ISC http] [00000000] [(null)] [(null)] 
type: sinkhole
srcip: 190.49.157.231
srcport: 9085
dstip: 149.20.56.34
dstport: 80
request:
GET /search?q=0 HTTP/1.0
User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; MEGAUPLOAD 1.0)
Host: 149.20.56.34
Pragma: no-cache

."
		rv = msgmod.pres_to_payload(pres)
		puts rv
		pp msgmod.pres_to_payload_finalize
	end

	should "read in a file, read 2 messages, and write out a file in presentation format" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		assert_not_nil(input)
		output = Nmsg::Output::Pres.new("test/test.pres")
		assert_not_nil(output)
		output.filter({:vid=>"ISC",:msgtype=>"http"})
		output.rate = 10
		output.endline = "\n\t"
		input.loop :count => 2 do |msg, usr|
			output.write(msg)
		end
		output.flush
		output.close
		pres = File.open("test/test.pres").read
		File.unlink("test/test.pres")
		assert_equal("[208] [2011-05-30 23:59:59.976026699] [1:4 ISC http] [00000000] [(null)] [(null)] \n\ttype: sinkhole\n\tsrcip: 190.49.157.231\n\tsrcport: 9085\n\tdstip: 149.20.56.34\n\tdstport: 80\n\trequest:\n\tGET /search?q=0 HTTP/1.0\r\nUser-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; MEGAUPLOAD 1.0)\r\nHost: 149.20.56.34\r\nPragma: no-cache\r\n\r\n.\n\t\n[184] [2011-05-30 23:58:03.351270894] [1:4 ISC http] [ce058cba] [(null)] [(null)] \n\ttype: sinkhole\n\tsrcip: 12.33.204.210\n\tsrcport: 11541\n\tdstip: 204.152.184.139\n\tdstport: 80\n\trequest:\n\tGET /4vir/antispyware/loadadv.exe HTTP/1.0\r\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)\r\nHost: trafficconverter.biz\r\nPragma: no-cache\r\n\r\n.\n\t\n", pres)
	end

	should "read in a file, read 2 messages, and call a callback for each" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		assert_not_nil(input)
		class MyCallback
			attr_reader :count
			def initialize
				@count = 0
			end
			def receive_nmsg(inout,msg,user)
				@count += 1
			end
		end
		mcb = MyCallback.new
		output = Nmsg::Output::Callback.new mcb
		assert_not_nil(output)
		output.filter({:vid=>"ISC",:msgtype=>"http"})
		input.loop :count => 2 do |msg, usr|
			output.write(msg)
		end
		output.close
		assert_equal(2,mcb.count)
	end

	should "read in a file, read 2 messages, and write out a file in compressed presentation format" do
		input = Nmsg::Input::File.new("test/test.nmsg")
		assert_not_nil(input)
		output = Nmsg::Output::Pres.new("test/test.pres.gz")
		assert_not_nil(output)
		output.gzipped = true
		input.loop :count => 2 do |msg, usr|
			output.write(msg)
		end
		output.flush
		output.close
		pres = File.open("test/test.pres.gz").read
		File.unlink("test/test.pres.gz")
		flunk "Gzipped never worked"
	end

	should "use an io engine to copy nmsg to presentation format" do
		io = Nmsg::IO.new
		assert_equal(0, io.input_count)
		assert_equal(0, io.output_count)
		io.add_input(Nmsg::Input::File.new("test/test.nmsg"))
		assert_equal(1, io.input_count)
		assert_equal(0, io.output_count)
		io.add_output(Nmsg::Output::Callback.new do |msg,user|
			puts msg
		end)
		assert_equal(1, io.input_count)
		assert_equal(1, io.output_count)
		io.count = 2
		io.start_cb(nil,"hi") do |thr,user| 
			puts thr
			puts user
			io.breakloop
		end
		io.exit_cb(nil,"bye") do |thr,user|
			puts thr
			puts user
			io.breakloop
		end
		io.close_cb do |event|
			pp event
			io.breakloop
		end
		io.loop
		io.destroy
	end
end
