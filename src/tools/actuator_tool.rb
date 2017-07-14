require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/ball_joint_simulation.rb'
require 'src/algorithms/rigidity_tester.rb'

class ActuatorTool < Tool

  MIN_ANGLE_DEVIATION = 0.05

  def initialize(ui)
    super
    @simulation = BallJointSimulation.new
    @mouse_input = MouseInput.new(snap_to_edges: true)
    @angles = []
  end

  #
  # Sketchup Tool methods
  #

  def deactivate(view)
    Sketchup.active_model.active_view.animation = nil
    super
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    edge = @mouse_input.snapped_object
    return if edge.nil?

    edges_without_selected = Graph.instance.edges.values.reject { |e| e == edge }
    if RigidityTester.rigid?(edges_without_selected)
      puts 'still rigid!'
      return
    end

    Sketchup.active_model.start_operation('toggle edge to actuator', true)
    create_actuator(edge)
    view.invalidate
    Sketchup.active_model.commit_operation
    @edges = Graph.instance.edges.values.to_a.select {|e| e.link_type != 'actuator' }
    @angles = triangle_pair_angles
    Sketchup.active_model.start_operation('simulate structure', true)
    start_simulation(edge)
    Sketchup.active_model.commit_operation
    view.show_frame
    find_hinge_positions
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def draw(_view) end

  #
  # Tool logic
  #

  def find_hinge_positions
    rotation_axes = find_rotation_axes
    highlight_rotation_axes(rotation_axes)
  end

  def start_simulation(edge)
    @simulation.edge = edge
    @simulation.setup
    @simulation.start
    @simulation.update_world_by(1)
    @simulation.update_entities
  end

  def create_actuator(edge)
    edge.link_type = 'actuator'
  end

  def triangle_pair_angles
    @edges.map do |edge|
      valid_pairs = edge.adjacent_triangle_pairs.select do |pair|
        pair.all? { |t| t.complete? && !t.contains_actuator? }
      end
      valid_pairs.map do |t1, t2|
        t1.angle_between(t2)
      end
    end
  end

  def simulation_triangle_normal(t)
    pos1 = t.first_node.thingy.body.get_position(1)
    pos2 = t.second_node.thingy.body.get_position(1)
    pos3 = t.third_node.thingy.body.get_position(1)
    vector1 = pos1.vector_to(pos2)
    vector2 = pos1.vector_to(pos3)
    vector1.cross(vector2)
  end

  def simulation_triangle_pair_angles
    @edges.map do |edge|
      valid_pairs = edge.adjacent_triangle_pairs.select do |pair|
        pair.all? { |t| t.complete? && !t.contains_actuator? }
      end
      valid_pairs.map do |t1, t2|
        n1 = simulation_triangle_normal(t1)
        n2 = simulation_triangle_normal(t2)
        n1.angle_between(n2)
      end
    end
  end

  def angle_changed?(angle, other_angle)
    (angle - other_angle).abs > MIN_ANGLE_DEVIATION
  end

  def find_rotation_axes
    simulation_angles = simulation_triangle_pair_angles
    @edges.zip(@angles, simulation_angles).flat_map do |edge, angles1, angles2|
      has_changed = angles1.zip(angles2).any? { |a1, a2| angle_changed?(a1, a2) }
      if has_changed
        [edge]
      else
        []
      end
    end
  end

  def highlight_rotation_axes(edges)
    edges.each(&:highlight)
  end
end