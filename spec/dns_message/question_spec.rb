# frozen_string_literal: true

RSpec.describe DNSMessage::Question do
  let(:question) { "\xc0\x0c\x00\x01\x00\x01" }

  it "will parse question correctly" do
    ptr = DNSMessage::Pointer.new({ 0x0c => "cmol.dk" })
    q = described_class.parse(question, ptr, 0)
    expect(q).to have_attributes(name:  "cmol.dk",
                                 type:  DNSMessage::Type::A,
                                 klass: DNSMessage::Class::IN)
  end

  it "will build question correctly" do
    ptr = DNSMessage::Pointer.new({ "cmol.dk" => 0x0c })
    q = described_class.new(name: "cmol.dk",
                            type: DNSMessage::Type::A)
    expect(q.build(ptr, 0).bytes).to eq(question.bytes)
  end
end
