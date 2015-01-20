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


## Usage

A full tutorial on using 0mq is beyond the scope of this README. The sections below introduce the Ruby objects and methods that you'll typically use in a standard workflow.

### Creating Sockets

Each 0mq socket type has its own class, named with full caps to conform with 0mq's conventions (e.g. **EZMQ::PUB**, **EZMQ::DEALER**). Each inherits from **EZMQ::Socket** and has consistent behavior for setting options and connecting. A **Context** object is created automatically the first time a **Socket** is made and destroyed when the last one is garbage collected; in most cases you shouldn't have to manage it or care that it exists.

Each socket type makes the relevant [0mq socket options](http://api.zeromq.org/4-0:zmq-setsockopt) available as initialization options with sensible names (e.g. `:reconnect_interval` instead of ZMQ_RECONNECT_IVL). A few other options are available as well for one-step binding or connecting. The following is a *partial* list of the most interesting options:

* `:name` - Optional; used to identify the socket in log files and the ZMQ_IDENTITY for routing. A unique name will be assigned if unspecified.
* `:send_limit` - The high water mark (i.e. maximum queue size) for outgoing messages.
* `:receive_limit` - The high water mark (i.e. maximum queue size) for incoming messages.
* `:max_message_size` - The byte limit for incoming messages.
* `:bind` - Immediately begin listening at the specified address. (See below.)
* `:connect` - Immediately connect to a socket at the specified address. (See below.)

### Sending

#### Non-Blocking Send

### Receiving

#### Non-Blocking Receive

### Polling

### Sockets

#### REQ/REP

#### PUB/SUB

#### PUSH/PULL

#### PAIR

#### ROUTER

#### DEALER

### Monitoring

## Contributing

## About

### License
