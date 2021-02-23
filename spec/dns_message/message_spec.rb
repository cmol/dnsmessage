# frozen_string_literal: true

RSpec.describe DNSMessage::Message do
  let(:good_query) do
    "\x14\x4e\x01\x00\x00\x01\x00\x00\x00\x00\x00\x01\x04\x63\x6d\x6f" \
    "\x6c\x02\x64\x6b\x00\x00\x01\x00\x01\x00\x00\x29\x02\x00\x00\x00" \
    "\x00\x00\x00\x00"
  end

  let(:good_reply) do
    "\x14\x4e\x81\x80\x00\x01\x00\x01\x00\x00\x00\x01\x04\x63\x6d\x6f" \
    "\x6c\x02\x64\x6b\x00\x00\x01\x00\x01\xc0\x0c\x00\x01\x00\x01\x00" \
    "\x00\x1c\x20\x00\x04\x5d\x5a\x72\x37\x00\x00\x29\x10\x00\x00\x00" \
    "\x00\x00\x00\x00"
  end

  context "when parseing DNS query header" do
    let(:match_header) do
      have_attributes(qr:      DNSMessage::Message::QUERY,
                      rd:      1,
                      qdcount: 1,
                      ancount: 0,
                      nscount: 0,
                      arcount: 1)
    end

    it do
      q = described_class.new
      q.parse_header(good_query[0...12])
      expect(q).to match_header
    end
  end

  context "when parsing DNS query" do
    let(:match_query) do
      have_attributes(qr:          DNSMessage::Message::QUERY,
                      qdcount:     1,
                      arcount:     1,
                      questions:   match_array([
                                                 have_attributes(
                                                   name:  "cmol.dk",
                                                   type:  DNSMessage::Type::A,
                                                   klass: DNSMessage::Class::IN
                                                 )
                                               ]),
                      additionals: match_array([
                                                 have_attributes(
                                                   name:              "",
                                                   type:              DNSMessage::Type::OPT,
                                                   opt_udp:           512,
                                                   opt_rcode:         0,
                                                   opt_edns0_version: 0,
                                                   opt_z_dnssec:      0
                                                 )
                                               ]))
    end

    it do
      q = described_class.parse(good_query)
      expect(q).to match_query
    end
  end

  context "when parsing too short query" do
    it do
      expect { described_class.parse(good_query[0..10]) }.to raise_error(StandardError)
    end
  end

  it "will fail on reply type" do
    bad_query = good_query.dup
    bad_query[2] = [0x80].pack("c")
    expect { described_class.parse(bad_query).check_validity }
      .to raise_error(StandardError)
  end

  it "will fail on no questions in query" do
    bad_query = good_query.dup
    bad_query[4] = [0x0].pack("c")
    bad_query[5] = [0x0].pack("c")
    expect { described_class.parse(bad_query).check_validity }
      .to raise_error(StandardError)
  end

  context "when parsing DNS resource record" do
    let(:match_rr) do
      have_attributes(
        name:  "cmol.dk",
        ttl:   7200,
        klass: DNSMessage::Class::IN,
        type:  DNSMessage::Type::A,
        rdata: IPAddr.new("93.90.114.55")
      )
    end

    it do
      q = described_class.new
      ptr = DNSMessage::Pointer.new({ 0x0c => "cmol.dk" })
      expect(q.parse_records(good_reply, 1, 25, ptr)[0][0]).to match_rr
    end
  end

  context "when parsing DNS reply" do
    let(:answers) do
      match_array([
                    have_attributes(
                      name:  "cmol.dk",
                      ttl:   7200,
                      klass: DNSMessage::Class::IN,
                      type:  DNSMessage::Type::A,
                      rdata: IPAddr.new("93.90.114.55")
                    )
                  ])
    end

    let(:additionals) do
      match_array([
                    have_attributes(
                      name:              "",
                      type:              DNSMessage::Type::OPT,
                      opt_udp:           4096,
                      opt_rcode:         0,
                      opt_edns0_version: 0,
                      opt_z_dnssec:      0
                    )
                  ])
    end

    let(:match_reply) do
      have_attributes(qr:          DNSMessage::Message::REPLY,
                      qdcount:     1,
                      arcount:     1,
                      questions:
                                   match_array([
                                                 have_attributes(
                                                   name:  "cmol.dk",
                                                   klass: DNSMessage::Class::IN,
                                                   type:  DNSMessage::Type::A
                                                 )
                                               ]),
                      answers:     answers,
                      additionals: additionals)
    end

    it { expect(described_class.parse(good_reply)).to match_reply }
  end

  it "will build reply correctly" do
    r = described_class.parse(good_reply).build
    expect(r.bytes).to eq(good_reply.bytes)
  end

  context "when replying to query" do
    it do
      q = described_class.parse(good_query)
      r = described_class.reply_to(q)
      expect(r).to have_attributes(qr: DNSMessage::Message::REPLY, id: q.id,
                                   questions: q.questions)
    end
  end
end
