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

***Important:*** You *must* have a compatible version of the **libzmq**
library installed on your system. This gem does not come with the ZeroMQ
source and will not execute if one cannot be found. It's widely available
with the leading package managers:

* Ubuntu / Debian: `sudo apt-get install libzmq`
* CentOS / Red Hat: `sudo yum install zeromq`
* OS X: With [Homebrew](http://brew.sh), `brew install zeromq`

The current version of **EZMQ** is developed and tested on [ZeroMQ 3.2.5](https://github.com/zeromq/zeromq3-x/) and [4.0.5](https://github.com/zeromq/zeromq4-x/).
Compatibility on lower 3._x_ versions is not guaranteed, and trying to run
with 2._x_ or lower will raise a runtime error.

Version 4-specific features such as authentication and encryption are included
based on a version check at startup. **EZMQ** will attempt to autodetect and
use the most recent 0mq version on your system; if you want to override this and
specify a specific library, set the `ZMQ_LIB` environment variable to the name.

### The Gem

Simply add `gem 'ezmq'` to your project's [Gemfile](http://bundler.io) or
run `gem install ezmq` if you're not bundling for some reason.

**EZMQ** uses the [Ruby FFI](https://github.com/ffi/ffi) gem and thus
should work on Ruby 1.9 and above, JRuby, and Rubinius. Please file an issue
if you find any issues on your chosen platform.

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

The polling features provided by 0mq are not currently implemented by 0mq. Please let us know in the
Github issues for this project if you'd like this feature soon.

## Sockets

### REQ/REP

### PUB/SUB

### PUSH/PULL

### PAIR

### ROUTER

### DEALER

## Encryption

0mq 4._x_ offers optional support for encrypting traffic using elliptic curve cryptography. To enable this, one side of a connection (the "server") must generate a public/private keypair. The private key is known only to the server socket, and the public key must be supplied by client sockets as the **server key**. If the keys correspond and there are no other authentication rules, the two sockets then negotiate one-time encryption for the rest of the exchange.

### Generating Keys

The 0mq library has a function for randomly generating elliptic-curve keypairs. If clients will need to make reliable connections for a time period longer than a single application run, we strongly recommend creating a "long term" keypair in advance and managing it as you would other application secrets.  You can use the `EZMQ.keypair` convenience method to create matching public and private keys:

```ruby
public_key, private_key = EZMQ.keypair
```

### Server Side

A socket can be configured to run as an encrypted 

### Client Side


## Authentication

0mq 4._x_ offers optional support for authenticating connections by IP address, with a plain text username/password, or with public/private keypairs. To secure a connection, one end of it (generally the "server" side) must run an **authentication handler.** This is a limited-purpose socket listening thread that _must_ run inside the same application process as the server socket. The handler receives credentials and connection data when a new client tries to connect, and implements rules to determine whether the connetion will be allowed to continue.  A single handler can manage authentication for any number of sockets within the same process.

**EZMQ** makes this pattern easier by providing an **EZMQ::AuthHandler** class that understands the [ZAP protocol](http://rfc.zeromq.org/spec:27) and allows any number of **rule definitions.** Standard rules are provided for filtering by a static list of usernames/passwords, client certificates, or IP ranges; or you can write your own rules if you need database lookups or other dynamic verifications.

## Monitoring

## Contributing

## About

### License
