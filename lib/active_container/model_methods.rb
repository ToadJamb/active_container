module ActiveContainer
  module ModelMethods
    def wrap
      Wrapper.wrap self
    end

    def wrapped?
      false
    end
  end
end
