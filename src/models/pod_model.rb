class PodModel
  attr_reader :definition, :length

  def initialize
    @definition = Sketchup.active_model.definitions.load(ProjectHelper.component_directory + '/pod.skp')
    @definition.name = 'Pod'
    @length = @definition.bounds.depth
  end

  def valid?
    @definition.valid?
  end

end
