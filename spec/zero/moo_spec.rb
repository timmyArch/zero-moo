require 'spec_helper'
require 'zero/moo'
require 'zero/moo/subscriber'
require 'zero/moo/publisher'

describe Zero::Moo do
  it 'has a version number' do
    expect(Zero::Moo::VERSION).not_to be nil
  end

  %w{publisher subscriber}.each do |x|
    coonst = const_get("Zero::Moo::#{x.capitalize}")

    context "testing address validation for #{x}" do

      it 'should raise, because missing address' do
        expect{coonst.new}.to(
          raise_error(coonst::MissingAddressError))
      end

      it 'should raise, because invalid port in address' do
        expect{coonst.new address: '1.1.1.1:90000', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '1.1.1.1:ADJKL', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
      end

      it 'should raise, because missing port in address' do
        expect{coonst.new address: '1.1.1.1:', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '1.1.1.1', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
      end

      it 'should raise, because invalid socket in address' do
        expect{coonst.new address: '1.1.1.256:60000', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '.........:60000', type: :any}.to(
          raise_error(coonst::InvalidAddressError))
      end
      
      it 'should raise, because invalid socket type was given' do
        expect{coonst.new address: '1.1.1.256:60000', type: :moo}.to(
          raise_error(coonst::SocketTypeError))
      end

    end
  end

end

describe "Communication" do 

  context "type :any" do

    it "is type of puller - pusher concept" do
      a = Zero::Moo::Subscriber.new address: '1.1.1.1:64000', type: :any
      expect(a.instance_variable_get(:@type)).to be ZMQ::PULL
      a = Zero::Moo::Publisher.new address: '1.1.1.1:64000', type: :any
      expect(a.instance_variable_get(:@type)).to be ZMQ::PUSH
      GC.start
    end

    it "can registers callbacks" do
      a = Zero::Moo::Subscriber.new address: '1.1.1.1:64000', type: :any
      expect(a).not_to be nil
      expect(a.instance_variable_get(:@receivers)).to be nil
      a.on_receive{|x| x}
      expect(a.instance_variable_get(:@receivers)).to be_an_instance_of Array
      expect(a.instance_variable_get(:@receivers).first).to be_an_instance_of Proc
      GC.start
    end

    it "should start listen thread" do
      a = Zero::Moo::Subscriber.new address: 'localhost:64000', type: :any
      expect(a.send(:listen!)).to be_an_instance_of Thread
      expect(a.send(:thread)).to be_an_instance_of Thread
      expect(a.send(:thread).alive?).to be true
      GC.start
    end

    it "should start thread automatically after calling on_receive" do
      a = Zero::Moo::Subscriber.new address: 'localhost:64000', type: :any
      a.on_receive{|x| x}
      expect(a.send(:thread)).to be_an_instance_of Thread
      expect(a.send(:thread).alive?).to be true
      GC.start
    end

    it "should give the message as callback argument" do
      @message = []
      #a = Zero::Moo::Subscriber.new address: 'localhost:64001', type: :any
      #a.on_receive{|x| @message << x }
      # sleep before pushing, because zmq is to fast
      sleep 1
      p = Zero::Moo::Publisher.new address: '127.0.0.1:64001', type: :any
      30.times{|i| p.push! "moo#{i}" }
      sleep 1
      expect(@message).to eq(["moo0", "moo1", "moo2"])
      GC.start
    end

  end

  context "type :all" do
    
    it "is type of subscriber - publisher concept" do
      a = Zero::Moo::Subscriber.new address: '1.1.1.1:64000', type: :all
      expect(a.instance_variable_get(:@type)).to be ZMQ::SUB
      a = Zero::Moo::Publisher.new address: '1.1.1.1:64000', type: :all
      expect(a.instance_variable_get(:@type)).to be ZMQ::PUB
      GC.start
    end
    
    it "should receive multiple messages" do
      @message = []
      #a = Zero::Moo::Subscriber.new address: 'localhost:64002', type: :all
      #a.on_receive('q1', 'q2'){|x| @message << x }
      # sleep before pushing, because zmq is to fast
      sleep 1
      p = Zero::Moo::Publisher.new address: '127.0.0.1:64002', type: :all
      30.times{|i| p.push! "moo#{i}", topic: ['q1'] }
      sleep 1
      expect(@message).to eq(["moo0", "moo1", "moo2"])
      GC.start
    end

  end

end

