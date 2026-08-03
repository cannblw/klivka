# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@atlaskit/pragmatic-drag-and-drop", to: "pragmatic-drag-and-drop.js" # @2.0.1
pin "@atlaskit/pragmatic-drag-and-drop-hitbox", to: "pragmatic-drag-and-drop.js", preload: false # @2.0.0
pin "@atlaskit/pragmatic-drag-and-drop-auto-scroll", to: "pragmatic-drag-and-drop.js", preload: false # @3.0.0
