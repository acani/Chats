require './config/application'
use Rack::Protection::PathTraversal
run Chats.new
