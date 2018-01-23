require 'src/tools/tool'
require 'src/database/graph.rb'

class GeneticActuatorPlacementTool < Tool
  def initialize(ui)
    super(ui)
  end

  def create_actuator(edge)
    Sketchup.active_model.start_operation('toggle edge to actuator', true)
    edge.link_type = 'actuator'
    edge = Graph.instance.create_edge(edge.first_node, edge.second_node, model_name: 'actuator', link_type: 'actuator')
    Sketchup.active_model.commit_operation
  end

  def uncreate_actuator(edge)
    Sketchup.active_model.start_operation('toggle actuator to edge', true)
    edge.link_type = 'bottle_link'
    edge = Graph.instance.create_edge(edge.first_node, edge.second_node, model_name: 'hard', link_type: 'bottle_link')
    Sketchup.active_model.commit_operation
  end

  def activate
    closest_distance = Float::INFINITY
    best_piston = nil
    Graph.instance.edges.values.each do |edge|
      next if edge.fixed?
      create_actuator(edge)
      @simulation = BallJointSimulation.new
      @simulation.setup
      # @simulation.disable_gravity
      piston = edge.thingy.piston
      piston.controller = 0.4
      @simulation.schedule_piston_for_testing(edge)
      @simulation.start
      distance = @simulation.test_pistons_for(2)
      if distance < closest_distance
        closest_distance = distance
        best_piston = edge
      end
      uncreate_actuator(edge)
      @simulation.stop
    end
    create_actuator(best_piston) unless best_piston.nil?
  end

  def onMouseMove(_flags, x, y, view)
  end

  def draw(view)
  end
end
