require 'erb'
require 'json'

post = JSON.parse(ARGV[0])

template = File.read('form.erb')

html = ERB.new(template, nil, '-').result

File.write('form.html', html)
