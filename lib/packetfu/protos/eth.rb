require 'packetfu/protos/eth/header'
require 'packetfu/protos/eth/mixin'

module PacketFu
	# EthPacket is used to construct Ethernet packets. They contain an
	# Ethernet header, and that's about it.
	#
	# == Example
	#
	#   require 'packetfu'
	#   eth_pkt = PacketFu::EthPacket.new
	#   eth_pkt.eth_saddr="00:1c:23:44:55:66"
	#   eth_pkt.eth_daddr="00:1c:24:aa:bb:cc"
	#
	#   eth_pkt.to_w('eth0') # Inject on the wire. (require root)
	#
	class	Ethernet < Packet
    VALID_ETHERTYPES = {
      0x0800 => IPv4,
      0x0806 => ARP,
      0x86dd => IPv6,
      0x88cc => LLDP,
    }.freeze

    HEADER_LENGTH = 14

    include ::PacketFu::EthHeaderMixin

		attr_accessor :eth_header

		def self.can_parse?(str)
			# XXX Temporary fix. Need to extend the EthHeader class to handle more.
			return false unless str.size >= 14
			type = str[12,2].unpack("n").first rescue nil
			return false unless VALID_ETHERTYPES.include? type
			true
		end

    def self.read(str=nil,args={})
      new.read str, args
    end

		def read(str=nil,args={})
      # TODO: Let the parser raise this rather than checking manually
			raise "Cannot parse `#{str}'" unless self.class.can_parse?(str)
			@eth_header.read(str[0, HEADER_LENGTH])
      @body = VALID_ETHERTYPES[@eth_header.ethertype].read str[14, str.length - HEADER_LENGTH]

			return self
		end

		# Does nothing, really, since there's no length or
		# checksum to calculate for a straight Ethernet packet.
		def recalc(args={})
			@headers[0].inspect
		end

		def initialize(args={})
			@eth_header = EthHeader.new(args).read(args[:eth])
			super
			@headers << @eth_header
		end

	end

end

# vim: nowrap sw=2 sts=0 ts=2 ff=unix ft=ruby
