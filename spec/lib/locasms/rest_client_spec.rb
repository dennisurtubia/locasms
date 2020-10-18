# frozen_string_literal: true

require 'spec_helper'

describe LocaSMS::RestClient do
  let(:callback) { 'http://example.com/callback' }
  let(:params) { { lgn: 'LOGIN', pwd: 'PASSWORD', url_callback: callback } }

  describe '.initialize' do
    context 'when giving proper initialization parameters' do
      subject { described_class.new :url, :params }
      it { expect(subject.base_url).to be(:url) }
      it { expect(subject.base_params).to be(:params) }
    end
  end

  describe '#get' do
    let(:action) { 'sendsms' }
    let(:body) { '{"status":1,"data":28,"msg":null}' }

    subject { described_class.new(action, params) }

    it 'Performs get request to url with parameters' do
      expect(Net::HTTP)
        .to receive(:get_response)
        .and_return(OpenStruct.new(body: body))

      subject.get(action, params)
    end
  end

  describe '#params_for' do
    subject { described_class.new :url, params }

    it { expect(subject.params_for(:action)).to eq({ action: :action }.merge(params)) }
    it { expect(subject.params_for(:action, p1: 10)).to eq({ action: :action, p1: 10 }.merge(params)) }

    context 'when callback is nil' do
      let(:callback) { nil }

      it 'is not in params' do
        expect(subject.params_for(:action)).to eq({ action: :action, lgn: 'LOGIN', pwd: 'PASSWORD' })
      end
    end
  end

  describe '#parse_response' do
    subject { described_class.new :url, :params }

    it 'raises exception on invalid operation' do
      expect { subject.parse_response(:action, '0:OPERACAO INVALIDA') }.to raise_error(LocaSMS::InvalidOperation)
    end

    it 'raises exception on a failed response' do
      response = '{"status":0,"data":null,"msg":"FALHA EPICA"}'

      expect { subject.parse_response(:action, response) }.to raise_error(LocaSMS::Exception, 'FALHA EPICA')
    end

    it 'raises exception on a failed login attempt' do
      response = '{"status":0,"data":null,"msg":"FALHA AO REALIZAR LOGIN"}'

      expect { subject.parse_response(:action, response) }.to raise_error(LocaSMS::InvalidLogin)
    end

    it 'returns the non-json value as a json' do
      response = { 'status' => 1, 'data' => 'non-json return', 'msg' => nil }

      expect(subject.parse_response(:action, 'non-json return')).to eq(response)
    end

    it 'returns a parsed json return' do
      response = { 'status' => 1, 'data' => 28, 'msg' => nil }

      expect(subject.parse_response(:action, '{"status":1,"data":28,"msg":null}')).to eq(response)
    end
  end
end
