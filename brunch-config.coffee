exports.config =
  files:
    javascripts:
      joinTo:
        'js/app.js': /^(vendor|bower_components|app)/
      pluginHelpers: 'js/app.js'
    stylesheets:
      joinTo:
        'css/app.css': /^(vendor|bower_components|app)/
    templates:
      joinTo: 'js/app.js'
  plugins:
    autoReload:
      enabled:
        js: on
        css: on
        assets: on
    imageoptimizer:
      path: 'images'
      smushit: no
    coffeelint:
      pattern: /^app\/.*\.coffee$/
      options:
        indentation:
          value: 2
          level: "warn"
        max_line_length:
          level: "ignore"
  conventions:
    assets: /(assets|vendor\/assets|font)/
