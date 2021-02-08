RSpec.describe DNSMessage::ResourceRecord do

  it "will parse A record correctly" do
    a_record = "\xc0\x0c\x00\x01\x00\x01\x00\x00\x1c\x20\x00\x04\x5d\x5a\x72\x37"
    name_pointers = {0x0c => "cmol.dk"}
    rr = DNSMessage::ResourceRecord.new(a_record, name_pointers)
    expect(rr).to have_attributes(name: "cmol.dk",
                                  type: DNSMessage::Type::A,
                                  klass: DNSMessage::Class::IN,
                                  ttl: 7200,
                                  rdata: IPAddr.new("93.90.114.55"))
  end

  it "will parse TXT record correctly" do
    txt_record = \
      "\xc0\x0c\x00\x10\x00\x01\x00\x00\x1c\x1f\x00\x22\x21\x76\x3d\x73" \
      "\x70\x66\x31\x20\x69\x6e\x63\x6c\x75\x64\x65\x3a\x65\x6d\x61\x69" \
      "\x6c\x73\x72\x76\x72\x2e\x63\x6f\x6d\x20\x7e\x61\x6c\x6c"

    name_pointers = {0x0c => "cmol.dk"}
    rr = DNSMessage::ResourceRecord.new(txt_record, name_pointers)
    expect(rr).to have_attributes(name: "cmol.dk",
                                  type: DNSMessage::Type::TXT,
                                  klass: DNSMessage::Class::IN,
                                  ttl: 7199,
                                  rdata: "v=spf1 include:emailsrvr.com ~all")
  end

end
