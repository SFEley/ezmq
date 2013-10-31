require 'fiddle/import'

module EZMQ

  # Compatibility layer for Ruby 2.0 and above. This version of the stdlib
  # deprecates DL in favor of Fiddle, but the APIs are very nearly the
  # same so most of the differences are in namespace.
  module API
    extend Fiddle::Importer

    Pointer = Fiddle::Pointer
    NULL = Fiddle::NULL

    INT_SIZE = Fiddle::SIZEOF_INT
    SIZE_T_SIZE = Fiddle::SIZEOF_SIZE_T
  end
end


