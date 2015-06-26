require 'aws-sdk'
require 'connection_pool'
require 'json'
require 'pg'
require 'rack/protection'
require 'securerandom'

uri = URI.parse(ENV['DATABASE_URL'])
$pg = ConnectionPool.new { PG.connect(uri.host, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password) }

require './config/routes'

require './app/controllers/codes_controller'
require './app/controllers/keys_controller'
require './app/controllers/me_controller'
require './app/controllers/sessions_controller'
require './app/controllers/users_controller'

require './app/helpers/authorization'
require './app/helpers/text_belt'
require './app/helpers/validation'
