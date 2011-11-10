def preload_lib(path)
  Dir["#{path}/**/*.rb"].sort.each do |file|
    require file.gsub("#{path}/", '').gsub('.rb', '')
  end
end

paths = $:.select { |path| path =~ %r(travis-|simple_states) }
paths << File.expand_path('..', __FILE__)

paths.each { |path| preload_lib(path) }
