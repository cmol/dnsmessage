# frozen_string_literal: true

RSpec.describe DNSMessage::Pointer do
  it "will add name to pointer" do
    p = described_class.new
    p.add("www.cmol.dk", 0x0c)
    expect(p.to_h).to eq({ "www.cmol.dk" => 0x0c,
                           "cmol.dk"     => 0x10 })
  end

  it "will add pointer to name" do
    p = described_class.new
    p.add(0x0c, "www.cmol.dk")
    expect(p.to_h).to eq({ 0x0c => "www.cmol.dk",
                           0x10 => "cmol.dk" })
  end

  it "will find inserted entry" do
    p = described_class.new({ "cmol.dk" => 0x0c })
    expect(p.find("cmol.dk")).to eq(0x0c)
  end
end
