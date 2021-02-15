# DNSMessage

DNSMessage is a Ruby library for building and parsing DNS messages.


## Features

A full featured DNS parser. The library supports DNS name compression
and gives access to parse, build, and manipulate all aspects of the DNS
queries and replies.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dnsmessage'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install dnsmessage

## Usage

```ruby
require 'dnsmessage'

# Parse some byte string from a server or somewhere else
msg = DNSMessage::Message.parse(byte_string)

# Look at the questions and resource records in that byte string
puts msg.questions.inspect
puts msg.answers.inspect
puts msg.additionals.inspect
puts msg.authority.inspect

# Create a reply based on the message (even if it's a reply itself)
reply = DNSMessage::Message.reply_to(msg)

# Add an answer to the reply
answer = DNSMessage::RR.new(name: "some.domain.tld",
                            type: DNSMessage::Type::A,
                            klass: DNSMessage::Class::IN,
                            ttl: 7200,
                            rdata: IPAddr.new("4.3.2.1"))
reply.answers << answer

# (optional) Add EDNS with a 512 maximum size
reply.additionals << DNSMessage::RR.default_opt(512)

# Build reply into a byte string
reply_bytes = reply.build

```

An example of an IP discovery server can be found in the examples
directory.

## Supported Resource Record types

Currently implemented types are:

* A
* AAAA
* CNAME
* OPT
* TXT

Other records should be easy to add on a per-need basis as they should
be based on the building blocks of already existing. Look at
contributing for details on adding RR types.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cmol/dnsmessage. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cmol/dnsmessage/blob/master/CODE_OF_CONDUCT.md).

### Adding Resource Record Types

To add a Resource Record you need to find documentation for the
structure of that record, or create a dump using something like
wireshark. After that is done, you can use an existing builder or parser
from `lib/dnsmessage/resource_record.rb`. If you are creating a pull
request, please add tests for the given type.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the dnsmessage project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/dnsmessage/blob/master/CODE_OF_CONDUCT.md).
