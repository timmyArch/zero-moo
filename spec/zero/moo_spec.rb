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
        expect{coonst.new address: '1.1.1.1:90000'}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '1.1.1.1:ADJKL'}.to(
          raise_error(coonst::InvalidAddressError))
      end

      it 'should raise, because missing port in address' do
        expect{coonst.new address: '1.1.1.1:'}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '1.1.1.1'}.to(
          raise_error(coonst::InvalidAddressError))
      end

      it 'should raise, because invalid socket in address' do
        expect{coonst.new address: '1.1.1.256:60000'}.to(
          raise_error(coonst::InvalidAddressError))
        expect{coonst.new address: '.........:60000'}.to(
          raise_error(coonst::InvalidAddressError))
      end

    end
  end

end

describe Zero::Moo::Subscriber do

  it "can registers callbacks" do
    a = Zero::Moo::Subscriber.new address: '1.1.1.1:64000'
    expect(a).not_to be nil
    expect(a.instance_variable_get(:@receivers)).to be nil
    a.on_receive{|x| x}
    expect(a.instance_variable_get(:@receivers)).to be_an_instance_of Array
    expect(a.instance_variable_get(:@receivers).first).to be_an_instance_of Proc
    GC.start
  end

  it "should start listen thread" do
    a = Zero::Moo::Subscriber.new address: 'localhost:64000'
    expect(a.send(:listen!)).to be_an_instance_of Thread
    expect(a.send(:thread)).to be_an_instance_of Thread
    expect(a.send(:thread).alive?).to be true
    GC.start
  end

  it "should start thread automatically after calling on_receive" do
    a = Zero::Moo::Subscriber.new address: 'localhost:64000'
    a.on_receive{|x| x}
    expect(a.send(:thread)).to be_an_instance_of Thread
    expect(a.send(:thread).alive?).to be true
    GC.start
  end

  it "should give the message as callback argument" do
    a = Zero::Moo::Subscriber.new address: 'localhost:64000'
    a.on_receive{|x| @message = x }
    expect(a.send(:thread)).to be_an_instance_of Thread
    expect(a.send(:thread).alive?).to be true

    p = Zero::Moo::Publisher.new address: '127.0.0.1:64000'
    p.push! "moo"
    sleep 1
    expect(@message).to eq("moo")
  end

end

