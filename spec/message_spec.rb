RSpec.describe DNSMessage::Message do
  good_query =
    "\x14\x4e\x01\x00\x00\x01\x00\x00\x00\x00\x00\x01\x04\x63\x6d\x6f" \
    "\x6c\x02\x64\x6b\x00\x00\x01\x00\x01\x00\x00\x29\x02\x00\x00\x00" \
    "\x00\x00\x00\x00"
  good_reply =
    "\x14\x4e\x81\x80\x00\x01\x00\x01\x00\x00\x00\x01\x04\x63\x6d\x6f" \
    "\x6c\x02\x64\x6b\x00\x00\x01\x00\x01\xc0\x0c\x00\x01\x00\x01\x00" \
    "\x00\x1c\x20\x00\x04\x5d\x5a\x72\x37\x00\x00\x29\x10\x00\x00\x00" \
    "\x00\x00\x00\x00"

  it "will parse DNS query header" do
    q = DNSMessage::Message.new()
    q.parse_header(good_query[0...12])
    expect(q).to have_attributes(qr: DNSMessage::Message::QUERY,
                                 rd: 1,
                                 qdcount: 1,
                                 ancount: 0,
                                 nscount: 0,
                                 arcount: 1)
  end

  it "will parse DNS query" do
    q = DNSMessage::Message.parse(good_query)
    expect(q).to have_attributes(qr: DNSMessage::Message::QUERY,
                                 qdcount: 1,
                                 arcount: 1,
                                 questions: [["cmol.dk",
                                     DNSMessage::Type::A,
                                     DNSMessage::Class::IN]]
                                )
  end

  it "will fail on too short query" do
    expect {DNSMessage::Message.parse(good_query[0..10])}.to raise_error(StandardError)
  end
  it "will fail on reply type" do
    bad_query = good_query
    bad_query[2] = [0x80].pack("c")
    expect {DNSMessage::Message.parse(bad_query).check_validity}
      .to raise_error(StandardError)
  end
  it "will fail on no questions in query" do
    bad_query = good_query
    bad_query[4] = [0x0].pack("c")
    bad_query[5] = [0x0].pack("c")
    expect {DNSMessage::Message.parse(bad_query).check_validity}
      .to raise_error(StandardError)
  end

  it "will parse DNS name directly" do
    r = DNSMessage::Message.new()
    name, _ = r.parse_name(good_reply, 12)
    expect(name).to eq("cmol.dk")
  end

  it "will parse DNS name via pointer" do
    r = DNSMessage::Message.new()
    name, _ = r.parse_name(good_reply, 25)
    expect(name).to eq("cmol.dk")
  end

  it "will parse DNS record" do
    q = DNSMessage::Message.new()
    expect(q.parse_records(good_reply, 1, 25)).to \
      eq([[["cmol.dk",
           DNSMessage::Type::A,
           DNSMessage::Class::IN,
           7200,
           "\x5d\x5a\x72\x37"]],41])
  end

  it "will parse DNS reply" do
    q = DNSMessage::Message.parse(good_reply)
    expect(q).to have_attributes(qr: DNSMessage::Message::REPLY,
                                 qdcount: 1,
                                 arcount: 1,
                                 questions: [["cmol.dk",
                                     DNSMessage::Type::A,
                                     DNSMessage::Class::IN]],
                                 answers: [["cmol.dk",
                                     DNSMessage::Type::A,
                                     DNSMessage::Class::IN,
                                     7200,
                                     "\x5d\x5a\x72\x37"]]
                                )
  end
end
