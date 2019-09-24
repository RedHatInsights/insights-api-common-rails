module DefaultAsJson
  extend ActiveSupport::Concern

  included do
    let(:default_as) { :json }
    prepend RequestHelpersCustomized
  end

  module RequestHelpersCustomized
    %w[patch post put].each do |method|
      define_method(method) do |path, **kwargs|
        kwargs[:as] ||= default_as if default_as
        super(path, kwargs)
      end
    end
  end
end
