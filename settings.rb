class Settings

  attr_accessor :list

  def initialize
    fullPath = "./"
    settings = YAML.load_file(fullPath+'settings.yml')
    @list = settings
  end
end