# frozen_string_literal: true

require_relative 'audit_log/formatter'
require_relative 'audit_log/middleware'

module Insights::API::Common
  # Audit Logger into selected logger, but primarily to CloudWatch
  class AuditLog
    class << self
      def logger
        @logger ||= init_logger
      end

      def logger=(logger)
        @logger = init_logger(logger)
      end

      def setup(logger = nil)
        self.logger = logger
      end

      def with_account(account_number)
        original = Thread.current[:audit_account_number]
        Thread.current[:audit_account_number] = account_number
        return unless block_given?

        yield
        Thread.current[:audit_account_number] = original
      end

      private

      def init_logger(logger = nil)
        logger ||= Logger.new($stdout)
        logger.level = Logger::INFO
        logger.formatter = Formatter.new
        logger
      end
    end
  end
end
