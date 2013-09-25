require 'ffi'

module EZmq
  extend FFI::Library
  ffi_lib 'libzmq'
end
