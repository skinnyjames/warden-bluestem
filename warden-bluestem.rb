#!/usr/bin/ruby -w

# Warden Bluestem is a warden strategy using the little Bluestem protocol and Rack::Warden
# Configuration is located in /config/initializers/bluestem.rb  
# This module adds a resident strategy, which is specific to UIC Campus Housing applications.

requre 'warden/bluestem'
Warden::Strategies.add :is_authenticated, Warden::Bluestem::Strategy
Warden::Strategies.add :is_resident, Warden::Bluestem::ResidentStrategy
