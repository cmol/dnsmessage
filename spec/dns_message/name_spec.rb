# frozen_string_literal: true

RSpec.describe DNSMessage::Name do
  let(:name_ptr) { DNSMessage::Pointer.new({ "cmol.dk" => 0x0c }) }
  let(:ptr_name) { DNSMessage::Pointer.new({ 0x0c => "cmol.dk" }) }

  it "will parse DNS name directly" do
    message = "\x04\x63\x6d\x6f\x6c\x02\x64\x6b\x00"
    name, = described_class.parse(message, name_ptr)
    expect(name).to eq("cmol.dk")
  end

  it "will parse DNS name via pointer" do
    message = "\xc0\x0c"
    name, = described_class.parse(message, ptr_name)
    expect(name).to eq("cmol.dk")
  end

  it "will build DNS name directly" do
    message = "\x04\x63\x6d\x6f\x6c\x02\x64\x6b\x00"
    name, = described_class.build("cmol.dk", DNSMessage::Pointer.new)
    expect(name).to eq(message)
  end

  it "will build DNS name from pointer" do
    message = "\xc0\x0c"
    name, = described_class.build("cmol.dk", name_ptr)
    expect(name.bytes).to eq(message.bytes)
  end
end
