# EZMQ

EZMQ is a next-generation Ruby binding for the [ZeroMQ](http://zeromq. org) messaging library. The design goal is to provide the simplest, most Rubyish interface possible on top of 0MQ's sockets. Seriously:

```ruby
require 'ezmq'

alice = EZMQ::PAIR.new bind: :inproc
bob = EZMQ::PAIR.new connect: alice

alice.send "Hello world!"
puts bob.receive  # => "Hello world!"
```

This example isn't as contrived as it looks. A few interesting things:

* A global 0MQ *Context* is created the first time a *Socket* needs one. It's smart enough to track and close all of its sockets if it goes out of scope or the application exits. If you need multiple contexts you can create them, but in most cases you'll never need to think about them at all.
* You can bind and/or connect sockets on creation or at any time after. You can query the Socket object for lists of connections and bindings. 
* Endpoints for binding can be specified as proper URIs ("tcp://192.168.100.100:9876") or you can provide shortcut symbols for certain transports:
    * The `:inproc` shortcut creates an internal transport with an automatically generated name.
    * The `:ipc` shortcut creates a Unix domain socket in a temp directory with a random unique filename.
    * The `:tcp` shortcut binds to a system-assigned available port on all network addresses. 
* You can connect to an endpoint by its address string or by passing a local Socket object. Passing a Socket will connect to the first "inproc://" transport it 
finds on that socket, creating one if needed.
* Socket options are all attributes on the *Socket* object.
* Outgoing messages can be given as strings (single-part) or lists of 
strings (multi-part). The strings are sent as binary bytes so encoding in 
this direction isn't important.
* Incoming messages appear as *Message* objects, which duck type to arrays 
but can be coerced to strings with a user-supplied part separator
(a la `Array#join`). Encodings can be specified globally or on a 
per-message basis.
* Failures from the 0MQ library raise Ruby exceptions. There's no need for
asserts or checking error codes after each operation.

## Compatibility

***Important:*** You *must* have a compatible version of the **libzmq**
library installed on your system. This gem does not come with the ZeroMQ
source and will not execute if one cannot be found.

The current version of **EZMQ** is developed and tested on [ZeroMQ 3.2._x_](https://github.com/zeromq/zeromq3-x/). Compatibility layers for [2.2._x_](https://github.com/zeromq/zeromq2-x/) and [4._x_](https://github.com/zeromq/zeromq4-x/) are
planned.

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









