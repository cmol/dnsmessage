RSpec.describe DNSMessage::Name do

  it "will parse DNS name directly" do
    message = "\x04\x63\x6d\x6f\x6c\x02\x64\x6b\x00"
    name, _, _ = DNSMessage::Name.parse(message, {})
    expect(name).to eq("cmol.dk")
  end

  it "will parse DNS name via pointer" do
    message = "\xc0\x0c"
    name, _, _ = DNSMessage::Name.parse(message, {0x0c => "cmol.dk"})
    expect(name).to eq("cmol.dk")
  end


end
