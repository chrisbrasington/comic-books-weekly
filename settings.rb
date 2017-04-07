class Settings

  attr_accessor :list

  def initialize (path)
    settings = YAML.load_file(path)
    @list = settings
  end
end