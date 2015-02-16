require 'spec_helper'

describe FayeRails::Controller::Channel do

  let(:channel) { double(:channel) }
  let(:endpoint) { double(:endpoint) }
  let(:client) { double(:client) }
  subject { FayeRails::Controller::Channel.new(channel, endpoint) }

  describe '#client' do
    example do
      FayeRails.should_receive(:client).with(endpoint)
      subject.client
    end
  end

  describe '#publish' do
    example do
      subject.should_receive(:client).and_return(client)
      client.should_receive(:publish).with(channel, "Hello bob")
      subject.publish("Hello bob")
    end
  end

  describe "#monitor" do
    it "raises ArgumentError for unknown event" do
      expect { subject.monitor(:blarg) }.to raise_error(ArgumentError, /^Unknown event/)
    end

    example do
    end
  end

end
