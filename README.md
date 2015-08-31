# Zero::Moo

An easy to use publisher - subscriber communication util.

*It is currently hard under development. 
There is no recovery after server restart* 

Unit tests will also follow.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zero-moo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zero-moo

## Usage

### Publisher - Subscriber

**Add a subscriber: **

```ruby
 require 'zero/moo/subscriber'
 s = Zero::Moo::Subscriber address: '127.0.0.1:64000'
 s.on_receive('topic1'){|message| puts message}
```

**Add a publisher: **

```ruby
 require 'zero/moo/publisher'
 p = Zero::Moo::Publisher address: '127.0.0.1:64000'
 p.push! "moo", topic: 'topic1'
```

### Pusher - Puller

**Add a puller: **

```ruby
 require 'zero/moo/puller'
 s = Zero::Moo::Puller address: '127.0.0.1:64000'
 s.on_receive{|message| puts message}
```

**Add a pusher: **

```ruby
 require 'zero/moo/pusher'
 p = Zero::Moo::Pusher address: '127.0.0.1:64000'
 p.push! "moo"
```



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/timmyArch/zero-moo.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

