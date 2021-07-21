require 'cloudwatchlogger'

describe Insights::API::Common::Metrics do
  let(:rails_config) { Rails.application.config }

  subject { Insights::API::Common::Logging.activate(rails_config) }

  context "development environment" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    end

    it "return proper logger class" do
      expect(subject.class).to eq(ManageIQ::Loggers::Base)
    end

    context "haberdasher is set as log_handler" do
      before do
        ENV['LOG_HANDLER'] == "haberdasher"
      end

      it "return proper logger class" do
        expect(subject.class).to eq(ManageIQ::Loggers::Base)
      end
    end
  end

  context "production environment" do
    before do
      ENV["CW_AWS_ACCESS_KEY_ID"] = "test"
      ENV["CW_AWS_SECRET_ACCESS_KEY"] = "test"
      ENV["CLOUD_WATCH_LOG_GROUP"] = "test"
      ENV["HOSTNAME"] = "test"
      allow(CloudWatchLogger::Client::AWS_SDK::DeliveryThreadManager).to receive(:new)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    it "return proper logger class" do
      expect(subject.class).to eq(Insights::Loggers::CloudWatch)
    end

    context "haberdasher is set as log_handler" do
      before do
        ENV['LOG_HANDLER'] = "haberdasher"
      end

      it "return proper logger class" do
        expect(subject.class).to eq(Insights::Loggers::StdErrorLogger)
      end
    end
  end
end
