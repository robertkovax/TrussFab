require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/ball_joint_simulation.rb'
require 'src/algorithms/rigidity_tester.rb'
require 'src/simulation/joints'
require 'src/simulation/thingy_rotation'

class ActuatorTool < Tool

  MIN_ANGLE_DEVIATION = 0.05

  def initialize(ui)
    super
    @mouse_input = MouseInput.new(snap_to_edges: true)
  end

  #
  # Sketchup Tool methods
  #

  def deactivate(view)
    Sketchup.active_model.start_operation('reset positions', true)
    @simulation.stop unless @simulation.nil?
    @simulation = nil
    Sketchup.active_model.commit_operation
    super
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    edge = @mouse_input.snapped_object
    return if edge.nil?
    if edge.link_type == 'actuator'
      edge.thingy.change_piston_group
    else
      edges_without_selected = Graph.instance.edges.values.reject { |e| e == edge }
      if RigidityTester.rigid?(edges_without_selected)
        puts 'still rigid!'
        create_actuator(edge, view)
        
        return
      end

      create_actuator(edge, view)

      edges = edges_without_selected.reject { |e| e.link_type == 'actuator' }
      original_angles = triangle_pair_angles(edges)
      start_simulation(edge)
      view.show_frame
      simulation_angles = simulation_triangle_pair_angles(edges)

      rotation_axes = find_rotation_axes(edges, original_angles, simulation_angles)
      highlight_rotation_axes(rotation_axes)
      add_hinges(rotation_axes)
      @simulation.stop

    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  #
  # Tool logic
  #

  def start_simulation(edge)
    @simulation = BallJointSimulation.new
    @simulation.setup
    @simulation.disable_gravity
    piston = edge.thingy.piston
    piston.controller = 0.4
    @simulation.start
    @simulation.update_world_by(2)
    Sketchup.active_model.start_operation('simulate structure', true)
    @simulation.update_entities
    Sketchup.active_model.commit_operation
  end

  def create_actuator(edge, view)
    Sketchup.active_model.start_operation('toggle edge to actuator', true)
    edge.link_type = 'actuator'
    view.invalidate
    Sketchup.active_model.commit_operation
  end

  def triangle_pair_angles(edges)
    edges.map do |edge|
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

  def simulation_triangle_pair_angles(edges)
    edges.map do |edge|
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

  def find_rotation_axes(edges, original_angles, simulation_angles)
    triples = edges.zip(original_angles, simulation_angles)
    triples.flat_map do |edge, angles1, angles2|
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

  def add_hinges(edges)
    edges.each do |rotation_axis|
      rotation_axis.adjacent_triangles.each do |triangle|
        (triangle.edges - [rotation_axis]).each do |rotating_edge|
          rotation = EdgeRotation.new(rotation_axis)
          node = rotating_edge.shared_node(rotation_axis)
          hinge = ThingyHinge.new(node, rotation)
          if rotating_edge.first_node?(node)
            rotating_edge.thingy.first_joint = hinge
          else
            rotating_edge.thingy.second_joint = hinge
          end
        end
      end
    end
  end
end