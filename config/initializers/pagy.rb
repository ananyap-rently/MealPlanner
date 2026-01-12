require 'pagy/extras/metadata'
require 'pagy/extras/overflow'
require 'pagy/extras/limit' # Add this if not present

Pagy::DEFAULT[:limit] = 10 # This replaces [:items]
Pagy::DEFAULT[:overflow] = :last_page