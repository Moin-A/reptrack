require 'rails_helper'

describe JwtTokenService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user)} 
  # Add your tests here
  context 'encode and decode logic' do
    let(:expected_result) {{:exp=>JwtTokenService::PAYLOAD_EXPIRATION, :sub=>user.email, :user_id=>user.id}}
    let(:payload_with_expired_token) { service.payload.tap do |token| token[:exp] = Time.now.to_i end}
      it 'payload consist of exp, sub and userid' do
     

        expect(service.payload).to eq(expected_result)
      end

      it 'payload is encoded properly' do
        encoded_payload = service.encode(service.payload);
        expect(service.decode(encoded_payload).transform_keys(&:to_sym)).to eq(expected_result)
      end

      it 'returns nil when token has expired' do
         encoded_payload = service.encode(payload_with_expired_token);
         expect(service.decode(encoded_payload)&.transform_keys(&:to_sym)).to eq(nil)
      end
   end
end 