RSpec.describe DNSMessage::Question do

  before(:each) do
    @question = "\xc0\x0c\x00\x01\x00\x01"
  end

  it "will parse question correctly" do
    ptr = DNSMessage::Pointer.new({0x0c => "cmol.dk"})
    q = DNSMessage::Question.parse(@question, ptr, 0)
    expect(q).to have_attributes(name: "cmol.dk",
                                  type: DNSMessage::Type::A,
                                  klass: DNSMessage::Class::IN)
  end

  it "will build question correctly" do
    ptr = DNSMessage::Pointer.new({"cmol.dk" => 0x0c})
    q = DNSMessage::Question.new(
      name: "cmol.dk",
      type: DNSMessage::Type::A
    )
    expect(q.build(ptr,0).bytes).to eq(@question.bytes)
  end
end
