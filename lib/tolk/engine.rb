module Tolk
  class Engine < Rails::Engine
    engine_name :tolk
    isolate_namespace(Tolk)
  end
end
