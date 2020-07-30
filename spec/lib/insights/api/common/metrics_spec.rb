require 'prometheus_exporter'
require 'prometheus_exporter/client'

describe Insights::API::Common::Metrics do
  let(:custom_metrics) do
    {
      :custom_metrics => [
        {
          :name      => "message_on_queue",
          :type        => :counter,
          :description => "total number of messages put on the queue"
        },
        {
          :name      => "error_processing_payload",
          :type        => :counter,
          :description => "total number of errors while attempting to messages put on the queue"
        }
      ]
    }
  end

  let(:metrics) { Insights::API::Common::Metrics }
  let(:prometheus) { PrometheusExporter::Client.new }

  before do
    # Dummy app doesn't listen here.
    allow(Rails).to receive_message_chain(:application, :middleware, :unshift)
  end

  describe ".setup_custom_metrics" do
    around do |example|
      PrometheusExporter::Client.default = prometheus
      metrics.instance_variable_set(:@metrics_port, port)

      example.call

      metrics.instance_variables.each { |e| metrics.remove_instance_variable(e) }
      PrometheusExporter::Client.default = nil
    end

    context "with metrics port set" do
      let(:port) { 9394 }

      before do
        metrics.activate(nil, "dummy_prefix", custom_metrics)
      end

      after do
        PrometheusExporter::Instrumentation::Process.stop
      end

      it "creates the singleton methods on the Metrics object" do
        expect(metrics.respond_to?(:message_on_queue)).to be_truthy
        expect(metrics.respond_to?(:error_processing_payload)).to be_truthy
      end

      it "adds instance vars to track the counts on the Metrics object" do
        expect(metrics.instance_values.keys).to match_array %w[message_on_queue_counter error_processing_payload_counter metrics_port]
      end

      it "adds the metrics defined in the hash" do
        expect(prometheus.instance_values["metrics"].map(&:name).uniq.count).to eq 2
        expect(prometheus.instance_values["metrics"].map(&:type).uniq).to match_array %I[counter]
      end
    end

    context "with metrics port zero" do
      let(:port) { 0 }

      before do
        metrics.activate(nil, "dummy_prefix", custom_metrics)
      end

      it "creates the singleton methods on the Metrics object" do
        expect(metrics.respond_to?(:message_on_queue)).to be_truthy
        expect(metrics.respond_to?(:error_processing_payload)).to be_truthy
      end

      it "adds instance vars to track the counts on the Metrics object" do
        expect(metrics.instance_values.keys).to match_array %w[metrics_port]
      end

      it "doesn't add the metrics defined in the hash" do
        expect(prometheus.instance_values["metrics"].map(&:name).uniq.count).to eq 0
      end
    end
  end
end
