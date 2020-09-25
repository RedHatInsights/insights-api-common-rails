module Insights
  module API
    module Common
      module OpenApi
        module VersionFromPrefix
          def api_version_from_prefix(prefix)
            /\/?\w+\/v(?<major>\d+)[x\.]?(?<minor>\d+)?\// =~ prefix
            [major, minor].compact.join(".")
          end
        end
      end
    end
  end
end
