require 'spec_helper'
require 'zero/moo'
require 'zero/moo/subscriber'
require 'zero/moo/publisher'
require 'zero/moo/puller'
require 'zero/moo/pusher'

describe Zero::Moo do
  it 'has a version number' do
    expect(Zero::Moo::VERSION).not_to be nil
  end

  %w{publisher subscriber}.each do |x|
    coonst = const_get("Zero::Moo::Abstract#{x.capitalize}")

    context "testing address validation for #{x}" do

      it 'should raise, because missing address' do
        expect{coonst.new}.to(
          raise_error(coonst::MissingAddressError))
      end

      it 'should raise, because invalid port in address' do
        expect{coonst.new address: '1.1.1.1:90000', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '1.1.1.1:ADJKL', type: :all}.to(
          raise_error(coonst::InvalidAddressError))
      end

      it 'should raise, because missing port in address' do
        expect{coonst.new address: '1.1.1.1:', type: :all}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '1.1.1.1', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
      end

      it 'should raise, because invalid socket in address' do
        expect{coonst.new address: '1.1.1.256:60000', type: :all}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '.........:60000', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
      end

      it 'should raise, because invalid socket type was given' do
        expect{coonst.new address: '1.1.1.256:60000', type: :yxcn}.to(
          raise_error(coonst::SocketTypeError))
      end

    end
  end

end

describe "Communication" do 

  context "Puller - Pusher" do

    it "is type of puller - pusher concept" do
      a = Zero::Moo::Pusher.new address: '0.0.0.0:64001'
      expect(a.instance_variable_get(:@type)).to be ZMQ::PUSH
      expect(a.pusher?).to be true
      expect(a.puller?).to be false
      s = Zero::Moo::Puller.new address: '0.0.0.0:64001'
      expect(s.instance_variable_get(:@type)).to be ZMQ::PULL
      expect(s.puller?).to be true
      expect(s.pusher?).to be false 
    end

    it "can registers callbacks" do
      a = Zero::Moo::Puller.new address: '0.0.0.0:64002'
      expect(a).not_to be nil
      expect(a.instance_variable_get(:@receivers)).to be nil
      a.on_receive{|x| x}
      expect(a.instance_variable_get(:@receivers)).to be_an_instance_of Array
      expect(a.instance_variable_get(:@receivers).first).to be_an_instance_of Proc
    end

    it "should start listen thread" do
      a = Zero::Moo::Puller.new address: 'localhost:64002'
      expect(a.send(:listen!)).to be_an_instance_of Thread
      expect(a.send(:thread)).to be_an_instance_of Thread
      expect(a.send(:thread).alive?).to be true
    end

    it "should start thread automatically after calling on_receive" do
      a = Zero::Moo::Puller.new address: 'localhost:64003'
      a.on_receive{|x| x}
      expect(a.send(:thread)).to be_an_instance_of Thread
      expect(a.send(:thread).alive?).to be true
    end

    it "should give the message as callback argument" do
      @message = []
      p = Zero::Moo::Pusher.new address: '127.0.0.1:64004'
      # sleep before pushing, because zmq is to fast
      sleep 1
      a = Zero::Moo::Puller.new address: 'localhost:64004'
      a.on_receive{|x| @message << x }
      sleep 1
      3.times{|i| p.push! "moo#{i}" }
      sleep 1
      expect(@message).to eq(["moo0", "moo1", "moo2"])
    end

  end

  context "Publisher - Subscriber" do

    it "is type of subscriber - publisher concept" do
      a = Zero::Moo::Publisher.new address: '0.0.0.0:64005'
      expect(a.instance_variable_get(:@type)).to be ZMQ::PUB
      s = Zero::Moo::Subscriber.new address: '1.1.1.1:64005'
      expect(s.instance_variable_get(:@type)).to be ZMQ::SUB
    end

    it "should receive multiple messages" do
      @message = []
      p = Zero::Moo::Publisher.new address: '127.0.0.1:64006'
      # sleep before pushing, because zmq is to fast
      sleep 1
      a = Zero::Moo::Subscriber.new address: 'localhost:64006'
      a.on_receive('q1'){|x| @message << x }
      sleep 1
      3.times{|i| p.push! "moo#{i}", topic: 'q1' }
      sleep 1
      expect(@message).to eq(["moo0", "moo1", "moo2"])
    end

  end

end

