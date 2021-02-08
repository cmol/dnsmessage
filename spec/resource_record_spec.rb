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

end
