# Gem entry point (required by Bundler). Loads the Pay dependency and the engine;
# the engine registers its app/ paths so Rails autoloads the processor classes,
# controller, and channel.
require "pay"
require "pay/razorback_processor/version"
require "pay/razorback_processor/engine"
