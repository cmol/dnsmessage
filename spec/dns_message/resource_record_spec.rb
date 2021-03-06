# frozen_string_literal: true

RSpec.describe DNSMessage::ResourceRecord do
  let(:ptr_name) { DNSMessage::Pointer.new({ 0x0c => "cmol.dk" }) }
  let(:name_ptr) { DNSMessage::Pointer.new({ "cmol.dk" => 0x0c }) }

  context "when parsing and building A records" do
    let(:a_record) { "\xc0\x0c\x00\x01\x00\x01\x00\x00\x1c\x20\x00\x04\x5d\x5a\x72\x37" }

    it "will parse A record correctly" do
      rr = described_class.parse(a_record, ptr_name)
      expect(rr).to have_attributes(name: "cmol.dk", type: DNSMessage::Type::A,
                                    klass: DNSMessage::Class::IN, ttl: 7200,
                                    rdata: IPAddr.new("93.90.114.55"))
    end

    it "will build A record correctly" do
      rr = described_class.new(name: "cmol.dk", type:  DNSMessage::Type::A,
        ttl: 7200, rdata: IPAddr.new("93.90.114.55"))
      expect(rr.build(name_ptr, 0).bytes).to eq(a_record.bytes)
    end
  end

  context "when parsing and building AAAA records" do
    let(:aaaa_record) do
      "\xc0\x0c\x00\x1c\x00\x01\x00\x00\x01\x68\x00\x10\x2a\x00" \
                    "\x0d\xf0\x01\x16\x01\x55\x00\x00\x00\x00\x00\x00\x00\x01"
    end

    it "will parse AAAA record correctly" do
      rr = described_class.parse(aaaa_record, ptr_name)
      expect(rr).to have_attributes(name:  "cmol.dk", type: DNSMessage::Type::AAAA,
                                    klass: DNSMessage::Class::IN, ttl:   360,
                                    rdata: IPAddr.new("2a00:df0:116:155::1"))
    end

    it "will build AAAA record correctly" do
      rr = described_class.new(name: "cmol.dk", type: DNSMessage::Type::AAAA,
        ttl: 360, rdata: IPAddr.new("2a00:df0:116:155::1"))
      expect(rr.build(name_ptr, 0).bytes).to eq(aaaa_record.bytes)
    end
  end

  context "when parsing and building txt records" do
    let(:txt_record) do \
      "\xc0\x0c\x00\x10\x00\x01\x00\x00\x1c\x1f\x00\x22\x21\x76\x3d\x73" \
        "\x70\x66\x31\x20\x69\x6e\x63\x6c\x75\x64\x65\x3a\x65\x6d\x61\x69" \
        "\x6c\x73\x72\x76\x72\x2e\x63\x6f\x6d\x20\x7e\x61\x6c\x6c"
    end

    it "will parse TXT record correctly" do
      rr = described_class.parse(txt_record, ptr_name)
      expect(rr).to have_attributes(name:  "cmol.dk", type:  DNSMessage::Type::TXT,
                                    klass: DNSMessage::Class::IN, ttl:   7199,
                                    rdata: "v=spf1 include:emailsrvr.com ~all")
    end

    it "will build TXT record correctly" do
      rr = described_class.new(name: "cmol.dk", type: DNSMessage::Type::TXT,
        ttl: 7199, rdata: "v=spf1 include:emailsrvr.com ~all")
      expect(rr.build(name_ptr, 0).bytes).to eq(txt_record.bytes)
    end
  end

  context "when parsing and building CNAME records" do
    let(:cname_record) { "\xc0\x0c\x00\x05\x00\x01\x00\x00\x1c\x20\x00\x02\xc0\x10" }

    it "will parse CNAME record correctly" do
      rr = described_class.parse(cname_record, ptr_name)
      expect(rr).to have_attributes(name: "cmol.dk", type: DNSMessage::Type::CNAME,
                                    klass: DNSMessage::Class::IN, ttl: 7200,
                                    rdata: "cmol.dk")
    end

    it "will build CNAME record correctly" do
      name_pointers = DNSMessage::Pointer.new({ "www.cmol.dk" => 0x0c,
                                                "cmol.dk"     => 0x10 })
      rr = described_class.new(name: "www.cmol.dk", type:  DNSMessage::Type::CNAME,
        ttl: 7200, rdata: "cmol.dk")
      expect(rr.build(name_pointers, 0).bytes).to eq(cname_record.bytes)
    end
  end

  context "when parsing and building OPT records" do
    let(:opt_record) { "\x00\x00\x29\x10\x00\x00\x00\x00\x00\x00\x00" }

    it "will parse OPT record correctly" do
      rr = described_class.parse(opt_record, ptr_name)
      expect(rr).to have_attributes(name: "", type: DNSMessage::Type::OPT,
                                    opt_udp: 4096, opt_rcode: 0,
                                    opt_edns0_version: 0, opt_z_dnssec: 0)
    end

    it "will build OPT record correctly" do
      rr = described_class.default_opt(4096)
      expect(rr.build(name_ptr, 0).bytes).to eq(opt_record.bytes)
    end

    it "will create default OPT record" do
      rr = described_class.default_opt(4096)
      expect(rr).to have_attributes(name: "", type: DNSMessage::Type::OPT,
                                    opt_udp: 4096, opt_rcode: 0,
                                    opt_edns0_version: 0, opt_z_dnssec: 0)
    end
  end
end
