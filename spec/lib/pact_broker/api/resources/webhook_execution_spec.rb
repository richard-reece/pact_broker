require 'spec_helper'
require 'pact_broker/api/resources/webhook_execution'

module PactBroker
  module Api
    module Resources

      describe WebhookExecution do

        describe "POST" do

          before do
            allow(PactBroker::Webhooks::Service).to receive(:find_by_uuid).and_return(webhook)
          end

          subject { post "/webhooks/some-uuid/execute"}

          context "when the webhook does not exist" do
            let(:webhook) { nil }

            it "returns a 404" do
              subject
              expect(last_response).to be_a_404_response
            end
          end

          context "when the webhook does exist" do
            let(:success) { true }
            let(:execution_result) { double('execution_result', success?: success, to_json: json)}
            let(:json) { {some: 'json'}.to_json }
            let(:webhook) { double("webhook", consumer_name: consumer_name, provider_name: provider_name) }
            let(:decorator) { instance_double(PactBroker::Api::Decorators::WebhookExecutionResultDecorator, to_json: json)}
            let(:pact) { instance_double("PactBroker::Domain::Pact") }
            let(:consumer_name) { "foo" }
            let(:provider_name) { "bar" }
            let(:webhook_options) do
              {
                logging_options: {
                  show_response: false,
                },
                webhook_context: {
                  base_url: "http://example.org"
                }
              }
            end

            before do
              allow(PactBroker::Webhooks::Service).to receive(:test_execution).and_return(execution_result)
              allow(PactBroker::Api::Decorators::WebhookExecutionResultDecorator).to receive(:new).and_return(decorator)
            end

            it "executes the webhook" do
              expect(PactBroker::Webhooks::Service).to receive(:test_execution).with(webhook, webhook_options)
              subject
            end

            context "when execution is successful" do
              it "returns a 200 JSON response" do
                subject
                expect(last_response).to be_a_hal_json_success_response
              end

              it "generates a JSON response body for the execution result" do
                allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return('foo')
                expect(decorator).to receive(:to_json).with(user_options: { base_url: 'http://example.org', webhook: webhook, show_response: 'foo' })
                subject
              end

              it "includes the execution result JSON in the body" do
                subject
                expect(last_response.body).to eq json
              end
            end

            context "when execution is not successful" do
              let(:success) { false }

              it "returns a 200 JSON response" do
                subject
                expect(last_response.status).to eq 200
              end

              it "includes the execution result JSON in the body" do
                subject
                expect(last_response.body).to eq json
              end
            end
          end
        end
      end
    end
  end
end
