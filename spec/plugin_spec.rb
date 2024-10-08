# spec/plugin_spec.rb
# frozen_string_literal: true

RSpec.describe LastDayUsedKey do
  let(:user) { Fabricate(:user) }
  let(:user_api_key) { Fabricate(:user_api_key, user: user) }
  let(:api_key) { Fabricate(:api_key, user: user) }

  describe '#update_last_used for UserApiKey' do
    it 'updates last_used_at to beginning of the day if not already set' do
      user_api_key.update!(last_used_at: 2.days.ago)

      expect {
        user_api_key.update_last_used("client_id_1")
      }.to change { user_api_key.reload.last_used_at }
         .to(Time.zone.now.beginning_of_day)
    end

    it 'does not update last_used_at if already set to beginning of the day' do
      user_api_key.update!(last_used_at: Time.zone.now.beginning_of_day)

      expect {
        user_api_key.update_last_used("client_id_1")
      }.not_to change { user_api_key.reload.last_used_at }
    end

    it 'updates client_id and destroys other keys with same client_id and user_id' do
      Fabricate(:user_api_key, user: user, client_id: "client_id_1")

      expect {
        user_api_key.update_last_used("client_id_1")
      }.to change { user_api_key.reload.client_id }.to("client_id_1")
      expect(UserApiKey.where(client_id: "client_id_1", user_id: user.id).count).to eq(1)
    end
  end

  describe '#update_last_used! for ApiKey' do
    it 'updates last_used_at to beginning of the day if not already set' do
      api_key.update!(last_used_at: 2.days.ago)

      expect {
        api_key.update_last_used!
      }.to change { api_key.reload.last_used_at }
         .to(Time.zone.now.beginning_of_day)
    end

    it 'does not update last_used_at if already set to beginning of the day' do
      api_key.update!(last_used_at: Time.zone.now.beginning_of_day)

      expect {
        api_key.update_last_used!
      }.not_to change { api_key.reload.last_used_at }
    end

    it 'calls the original method when last_used_at is nil' do
        allow(api_key).to receive(:super).and_call_original

        api_key.update_last_used!
        expect(api_key).to have_received(:super).with(Time.zone.now.beginning_of_day)
    end

    it 'skips updating if last_used_at is already beginning of the day' do
        api_key.update!(last_used_at: Time.zone.now.beginning_of_day)
        expect(api_key).not_to receive(:super)

        api_key.update_last_used!
    end
  end
end
