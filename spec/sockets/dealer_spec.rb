require 'spec_helper'
require_relative 'socket_shared'

module EZMQ

  describe DEALER do
    let(:other) {DEALER.new}

    it_behaves_like "every socket"
    it_behaves_like "a sending socket"
    it_behaves_like "a receiving socket"
  end

end
