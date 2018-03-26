class BallHubModel
  attr_reader :definition, :scaling

  def initialize
    Sketchup.active_model.start_operation('Create Ball Hub', true, false, true)
    @definition = Sketchup.active_model.definitions.load(ProjectHelper.component_directory + '/ball_hub.skp')
    @definition.name = 'Hub'

    radius = Configuration::BALL_HUB_RADIUS
    model_radius = @definition.bounds.depth / 2
    scaling_factor = radius / model_radius

    @scaling = Geom::Transformation.scaling(scaling_factor)
    Sketchup.active_model.commit_operation
  end

  def valid?
    @definition.valid?
  end

end
