require 'rails_helper'

RSpec.describe TasksController, type: :controller do
  let(:valid_attributes) { { name: "Fix login bug", description: "Investigate OAuth", due_date: 3.days.from_now, status: :completed } }
  let(:invalid_attributes) { { name: "" } }
  let(:pagination_params) { Task.buckets.keys.index_with(1) }
  let(:user) { create(:user, confirmed_at: Time.now) }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns a successful response" do
      get :index, params: { pagination: pagination_params }
      expect(response).to have_http_status(:ok)
    end

    it "returns tasks grouped by bucket" do
      task = create(:task, bucket: :today, user: user)
      get :index, params: { pagination: pagination_params }
      json = JSON.parse(response.body)
      expect(json["buckets"]).to be_a(Hash)
      expect(json["buckets"]["today"].first["id"]).to eq(task.id)
    end

    it "includes all buckets even when empty" do
      get :index, params: { pagination: pagination_params }
      json = JSON.parse(response.body)
      expected_buckets = Task.buckets.keys.map(&:to_s)
      expect(json["buckets"].keys).to match_array(expected_buckets)
    end
  end

  describe "GET #show" do
    let(:task) { create(:task, user: user) }

    it "returns a successful response" do
      get :show, params: { id: task.id }
      expect(response).to have_http_status(:ok)
    end

    it "returns the task" do
      get :show, params: { id: task.id }
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(task.id)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new Task" do
        expect {
          post :create, params: { task: valid_attributes }
        }.to change(Task, :count).by(1)
      end

      it "returns a created response" do
        post :create, params: { task: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Task" do
        expect {
          post :create, params: { task: invalid_attributes }
        }.not_to change(Task, :count)
      end

      it "returns unprocessable content" do
        post :create, params: { task: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    let(:task) { create(:task, user: user) }

    context "with valid parameters" do
      it "updates the task" do
        patch :update, params: { id: task.id, task: { name: "Updated name" } }
        expect(task.reload.name).to eq("Updated name")
      end

      it "returns a successful response" do
        patch :update, params: { id: task.id, task: { name: "Updated name" } }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid parameters" do
      it "does not update the task" do
        patch :update, params: { id: task.id, task: invalid_attributes }
        expect(task.reload.name).not_to eq("")
      end

      it "returns unprocessable content" do
        patch :update, params: { id: task.id, task: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST #complete" do
    let(:user2) { create(:user, confirmed_at: Time.now) }
    let!(:task) { create(:task, user: user2) }

    it "completes the task" do
      task.update(user: user)
      post :complete, params: { id: task.id }
      expect(task.reload.status).to eq("completed")
    end

    it "returns a cancan authorization error" do
     expect {
       post :complete, params: { id: task.id }
     }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "DELETE #destroy" do
    let!(:task) { create(:task, user: user) }

    it "destroys the task" do
      expect {
        delete :destroy, params: { id: task.id }
      }.to change(Task, :count).by(-1)
    end

    it "returns no content" do
      delete :destroy, params: { id: task.id }
      expect(response).to have_http_status(:no_content)
    end
  end
end
