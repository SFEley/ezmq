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

## Compatibility

***Important:*** You *must* have a compatible version of the **libzmq**
library installed on your system. This gem does not come with the ZeroMQ
source and will not execute if one cannot be found.

The current version of **EZMQ** is developed and tested on [ZeroMQ 3.2.5](https://github.com/zeromq/zeromq3-x/) and [4.0.5](https://github.com/zeromq/zeromq4-x/).
It *might* work on lower 3._x_ versions but compatibility is not guaranteed.

Version 4-specific features such as authentication and encryption are
implemented as modules and included based on a version check
at startup. **EZMQ** will attempt to autodetect and use the most recent
0mq version on your system; if you want to override this and specify a
specific library, set the `ZMQ_LIB` environment variable to the name.

Integration uses the [Ruby FFI](https://github.com/ffi/ffi) gem and thus
should work on Ruby 1.9 and above, JRuby, and Rubinius. Please file an issue
if you find any issues on your chosen platform.

The developer has no idea if any of this works on Windows. Feel free to let
him know if it does or doesn't.

## Usage

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
