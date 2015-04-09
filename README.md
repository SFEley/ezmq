# EZMQ

EZMQ is a next-generation Ruby binding for the [ZeroMQ](http://zeromq. org) messaging library. The design goal is to provide the simplest, most Rubyish interface possible on top of 0MQ's sockets. And by "simplest" we mean:

```ruby
require 'ezmq'

alice = EZMQ::PAIR.new
bob = EZMQ::PAIR.new connect: alice

alice.send "Hello world!"
puts bob.receive  # => "Hello world!"
```

A few interesting points:

* A global 0MQ *Context* is created the first time a *Socket* needs one. It's smart enough to track and close all of its sockets if it goes out of scope or the application exits. If you need multiple contexts you can create them, but in most cases you'll never need to refer to the context at all.
* You can bind and/or connect sockets on creation or at any time after.
Addresses can be specified as URI strings ("tcp://192.168.100.100:9876") or you can provide shortcut symbols for certain transports:
    * The `:inproc` shortcut creates an internal (thread-to-thread) transport with an automatically generated name.
    * The `:ipc` shortcut creates a Unix domain socket in a temp directory with a random unique filename.
    * The `:tcp` shortcut binds to a system-assigned port on all available addresses.
* You can also `connect` to a local socket object, as in the above example. This will connect to the first *inproc://* binding for that socket, creating one if needed.
* The `send` method accepts a string (single-part message) or list of strings (multi-part message). The strings are treated as binary bytes; encoding isn't important.
* The `receive` method returns a *Message* object, which duck types fairly well as a string or an array of strings (message parts).
* Failures from 0MQ raise Ruby exceptions. There's no need for asserts or checking error codes after each operation.

## Installation

### Getting ZeroMQ

***Important:*** You *must* have a compatible version of the **libzmq** library installed on your system. This gem does not come with the ZeroMQ source and will not execute if one cannot be found. It's widely available with the leading package managers:

* Ubuntu / Debian: `sudo apt-get install libzmq`
* CentOS / Red Hat: `sudo yum install zeromq`
* OS X: With [Homebrew](http://brew.sh), `brew install zeromq`

The current version of **EZMQ** is developed and tested on [ZeroMQ 3.2.5](https://github.com/zeromq/zeromq3-x/) and [4.0.5](https://github.com/zeromq/zeromq4-x/). Compatibility on lower 3._x_ versions is not guaranteed, and trying to run with 2._x_ or lower will raise a runtime error.

Version 4-specific features such as authentication and encryption are included based on a version check at startup. **EZMQ** will attempt to autodetect and use the most recent 0mq version on your system; if you want to override this and specify a specific library, set the `ZMQ_LIB` environment variable to the name.

### The Gem

Simply add `gem 'ezmq'` to your project's [Gemfile](http://bundler.io) or run `gem install ezmq` if you're not bundling for some reason.

**EZMQ** uses the [Ruby FFI](https://github.com/ffi/ffi) gem and thus should work on Ruby 1.9 and above, JRuby, and Rubinius. Please file an issue if you find any issues on your chosen platform.

## Configuration

**EZMQ** intentionally comes with few global options, and no setup is required to start using it. Individual sockets are highly configurable of course, but most settings will be very specific to that socket and there's little point in sharing them.  The following attributes are available
on the top-level **EZMQ** module:

* `EZMQ.logger`: Set this to any [Ruby Logger](http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger.html)-compatible object to capture details about socket and message activity. Broadly speaking, logging detail falls into error levels as follows:
  * *ERROR* - Non-retryable failures (host not found, sending to a closed socket, etc.)
  * *WARN* - Retryable or partial failures (high-water mark is reached, message truncated, etc.)
  * *INFO* - Socket opening/closing, new connections, subscribe/unsubscribe activity
  * *DEBUG* - Message sending and receiving activity
* `EZMQ.linger`: Sets the global default for the time (in milliseconds) to continue sending messages after a socket is closed. *EZMQ** defaults this to 0 for fast application quitting. Set it to a positive value to allow a grace period on closeout, or to *nil* to wait indefinitely. (Warning: this may cause your application to hang on shutdown if undeliverable messages are stuck in the queue.)


## Basic Usage

A full tutorial on using 0mq is beyond the scope of this README. The sections below introduce the Ruby objects and methods that you'll typically use in a standard workflow.

### Creating Sockets

Each 0mq socket type has its own class, named with full caps to conform with 0mq's conventions (e.g. **EZMQ::PUB**, **EZMQ::DEALER**). Each inherits from **EZMQ::Socket** and has consistent behavior for setting options and connecting. A **Context** object is created automatically the first time a **Socket** is made and destroyed when the last one is garbage collected; in most cases you shouldn't have to manage it or care that it exists.

Each socket type makes the relevant [0mq socket options](http://api.zeromq.org/4-0:zmq-setsockopt) available as initialization options with sensible names (e.g. `:reconnect_interval` instead of ZMQ_RECONNECT_IVL). A few other options are available as well for one-step binding or connecting. The following is a *partial* list:

* *:name* - Optional; used to identify the socket in log files and the ZMQ_IDENTITY for routing. A unique name will be assigned if unspecified.
* *:send_limit* - The high water mark (i.e. maximum queue count) for outgoing messages.
* *:receive_limit* - The high water mark (i.e. maximum queue count) for incoming messages.
* *:max_message_size* - The byte limit for incoming messages.
* *:bind* - Immediately begin listening at the specified address. (See below.)
* *:connect* - Immediately connect to a socket at the specified address. (See below.)

### Messages

A 0mq message is composed of any number of _parts_ or _frames_. The official docs use both terms interchangeably; EZMQ sticks with _frames_ for clarity.  Each frame is a binary string of any length. However, many use cases find it simpler to ignore this nuance and treat messages as atomic, with one string per message. In the Ruby world, where developers expect libraries to do the least surprising thing, this presents a dilemma: should methods that emit messages return _strings_, or _arrays_ of strings?

EZMQ resolves this with a **Message** object that duck types to both, with an interface informed by common sense. It delegates to the Array class, with each frame as a string element. So usages like `message[0..2]` or `message.each {|frame| ...}` will do what you expect, along with every other method on Array or Enumerable.

However, it also supports coercion via `#to_str` and `#to_s`, so Ruby methods that expect strings will get one. By default these simply concatenate all frames, with no added characters. If you'd prefer line breaks or pipes or funny squiggles between each frame, you can set them globally with the `Message::frame_separator` class method or on individual Message objects with `#frame_separator`.  For example:

```ruby
msg = Message.new("You've gotta fight", "for your right", "to party!")

puts msg
#=> You've gotta fightfor your rightto party!

Message.frame_separator = "\n"  # Sets default separator for every message
puts msg
#=> You've gotta fight
#=> for your right
#=> to party!

msg.frame_separator = "...*drum*..."  # Separator for this message only
puts msg
#=> You've gotta fight...*drum*...for your right...*drum*...to party!
```

Other nuances:

* Messages have an `::encoding` and `#encoding` which force the string encoding for every frame. It defaults to **Encoding::BINARY**, but you can set it to **Encoding::UTF_8** or whatever else makes sense for your data.
* You get the String-based `=~` and `match` methods for regexing the whole message.
* The message `size` (aliased to `length`) returns the total number of bytes (not characters) in all frames.
* However, the `count` returns the total number of frames. Don't confuse it with `size`.

### Sending

Sockets which can send messages -- i.e. everything except PULL, SUB and XSUB -- have a `send` method which takes any number of strings. (Or a Message object, but it's simpler to use strings most of the time.) Each string will be encoded to binary and represents a separate frame.

Normally the `send` method expects a complete message. If you'd prefer to _start_ a multiframe message now and finish it later, you can append the *more: true* option after all strings. This tells 0mq that more frames are pending. The next `send` call that does _not_ have a *more* option (or for which _more_ is false) will finalize the message and actually send it.

#### Non-Blocking Send

Under most circumstances the `send` method will push the message into the 0mq socket's sending queue and return immediately. However, there are edge cases in which a socket can't accept messages for sending, such as hitting the high-water mark for its send queue (or all receivers' receive queues), or when there are no connected sockets to send to. Most sockets will simply block on sending until the condition clears -- meaning that your `send` call may take longer than usual to finish.

If this is not acceptable, you can append the *async: true* option when sending. If the message can be sent immediately this makes no difference; but if it can't, an **EZMQ::EAGAIN** exception is raised instead of blocking and waiting. What to do with this exception is up to you.

### Receiving

Receiving a message is even simpler than sending one: just call the socket's `receive` method. The return value will be a **Message** object with the next message from the receive queue. If the queue is empty, the `receive` call will block until a message comes in.

It's a common pattern, especially in microservices, to build applications that do nothing but `receive` messages and process them. A simple loop suffices for this case:

```ruby
socket = EZMQ::PULL.new bind: 'tcp://1.2.3.4:5678'  # PUSH sockets will connect to this
while message = socket.receive
  # ...do stuff with message...
end
```

If your application needs to be able to do more than one thing at a time, and receiving 0mq messages is only part of its function, it's a good idea to wrap the above in a `Thread.new` block and let it keep processing in the background. Be sure to keep track of the thread object and kill it when your application is ready to exit, or you may have trouble shutting down.

#### Non-Blocking Receive

Waiting for a message to come in is the desired `receive` behavior 99% of the time. If you need it to return quickly at all times, pass the *async: true* option. This will cause an **EZMQ::EAGAIN** exception to be raised if there are no available messages.

### Polling

The polling features provided by 0mq are not currently implemented by 0mq. Please let us know in the Github issues for this project if you'd like this feature soon.

## Sockets

### REQ/REP

### PUB/SUB

### PUSH/PULL

### PAIR

### ROUTER

### DEALER

## Encryption

0mq 4._x_ offers optional support for encrypting traffic using [elliptic curve cryptography](http://curvezmq.org). To enable this, one side of a connection (the "server") must generate a public/private keypair. The secret key is known only to the server socket, and the public key must be supplied by client sockets as the **server key**. If the keys correspond and there are no other authentication rules, the two sockets then negotiate one-time encryption for the rest of the exchange.

***NOTE:*** Like many features of 0mq, the security handshake happens behind the scenes after the connection request returns. This means that there's no explicit error if the wrong keys are given or encryption otherwise fails. The only way to know you'll know your sockets aren't talking is that messages won't be received. Good integration tests are highly recommended.

### Generating Keys

The 0mq library has a function for randomly generating elliptic-curve keypairs. If clients will need to make reliable connections for a time period longer than a single application run, we strongly recommend creating a "long term" keypair in advance and managing it as you would other application secrets.  You can use the `EZMQ.keypair` convenience method to create matching public and secret keys:

```ruby
public_key, secret_key = EZMQ.keypair
#=> ['BB88471D65E2659B30C55A5321CEBB5AAB2B70A398645C26DCA2B2FCB43FC518',
#=>  '7BB864B489AFA3671FBE69101F94B38972F24816DFB01B51656B3FEC8DFD0888']
```

To globally set the keys for every socket created in your application, you can do the converse: 

```ruby
EZMQ.keypair = public_key, secret_key

# OR

EZMQ.public_key = public_key
EZMQ.secret_key = secret_key
```

You can also set these options on individual sockets, of course. Note that simply assigning keys will _not_ enable encryption; you'll also need to set server and client options.

### Server Side

One half of any encrypted connection must be designated as the server. Make sure a [secret key is set](#generating-keys) for this socket, then set *server: :encrypted* or *server: :curve* (they're synonymous) to turn on security:

```ruby
socket = EZMQ::PUB.new(secret_key: '7BB864B489AFA3671FBE69101F94B38972F24816DFB01B51656B3FEC8DFD0888', 
                       server: :encrypted )

# OR

socket = EZMQ::PUB.new
socket.secret_key = '7BB864B489AFA3671FBE69101F94B38972F24816DFB01B51656B3FEC8DFD0888'
socket.server = :encrypted
```

You must then distribute the matching _public_ key to anyone who wishes to communicate with this socket, and they'll have to set it on their client sockets. Any socket that doesn't provide the correct public key will fail to connect and messages will never go out.

### Client Side

To talk to an encrypted server socket, just set the *server_key* option to that socket's public key before conecting:

```ruby
socket = EZMQ::SUB.new(server_key: 'BB88471D65E2659B30C55A5321CEBB5AAB2B70A398645C26DCA2B2FCB43FC518')
socket.connect 'tcp://pubsocket.example.org:12345'

# OR

socket = EZMQ::SUB.new
socket.server_key = 'BB88471D65E2659B30C55A5321CEBB5AAB2B70A398645C26DCA2B2FCB43FC518'
socket.connect 'tcp://pubsocket.example.org:12345'
```

The client socket must also have valid [public and secret keys](#generating-keys), but remembering them in the long term is only useful if you intend to use them for [authentication](#authentication). If you don't set the client's keys yourself, a keypair will be automatically assigned when you set the *server_key*.

## Authentication

0mq 4._x_ offers optional support for verifying the identity of remote sockets by a number of means, including plain text usernames/passwords and encrypted public keys. Only one end of a socket pair can manage authentication; this socket is logically the _server_, but it doesn't matter if it connects or binds. A socket acts like a server (i.e. will attempt authentication) if either the *server* or the *domain* option is set to anything other than *nil*.

To perform the authentication, the owning application must run an **authentication handler** in a separate thread, which receives a message whenever a client connects to a server socket and returns a message indicating whether the connection is valid. **EZMQ** gives you three options for authentication handlers:

* **Roll your own.**  It's not that hard to create your own handler. Start by reading the specs for the [ZAP protocol](http://rfc.zeromq.org/spec:27). Then just create a REP socket, bind it to `inproc://zeromq.zap.01`, and handle requests as documented. **EZMQ** won't try to launch its own handler if there's already one listening.
* **Forward to another.** This is similar to the above, except the handler needn't run in the same process. Calling `EZMQ.auth_handler=` and assigning an endpoint string will set up a proxy that sends every authentication request to that destination. This allows many applications to use a centralized authentication service. The destination handler should be a ROUTER socket that follows the [ZAP protocol](http://rfc.zeromq.org/spec:27).
* **Use the built-in whitelist handler.** **EZMQ** comes with a simple but flexible authentication handler that starts automatically as soon as an [authorization rule](#authorization-rules) is added at any level (global, domain, or socket). The handler lets you check the client's metadata against static values or code blocks, and should be enough for use cases of low to moderate complexity. The rest of this section describes the behavior of the built-in handler.


### Authorization Rules

0mq allows only a single authentication handler in an application, but if you have a number of sockets you may need them to follow different sets of rules. **EZMQ**'s built-in handler allows you to scope those rules at three levels:

* **Global rules** apply to every server socket. You can manage global rules with `EZMQ.authorize` and `EZMQ.deauthorize`.
* **Domain rules** allow groups of sockets to share the same authentication behavior. A named domain is created whenever you set the *domain* option on a socket, and can be accessed from the `EZMQ.domains[]` hash. To manage the rules on every socket in the "foo" domain, you would call `EZMQ.domains['foo'].authorize` and `EZMQ.domains['foo'].deauthorize`.
* **Socket rules** are specific to a single socket and managed with the `#authorize` and `#deauthorize` methods on that socket object. The handler relies on the socket's *identity* (aka *name*) option to tell them apart. (Note: **EZMQ**'s default socket names are only guaranteed to be unique within a single application, so if you're going to forward to a distributed authentication handler, you should override these to be unique within your network.)

(TODO: document the *fields* the rules can match on, and explain the whitelist-if-not-empty filter for each field. Strings, regexes and blocks are all valid in the list.)


## Monitoring

## Contributing

## About

### License
