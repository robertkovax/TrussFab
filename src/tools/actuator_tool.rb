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
    super
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    edge = @mouse_input.snapped_object
    return if edge.nil?

    edges_without_selected = edge.connected_component.reject { |e| e == edge }
    if RigidityTester.rigid?(edges_without_selected)
      UI.messagebox('The structure is still rigid and would break with this actuator. Please remove more edges to enable this structure to move',
                    type = MB_OK)
      return
    end

    create_actuator(edge, view)

    edges = edges_without_selected.reject { |e| e.link_type == 'actuator' }
    triangle_pairs = edges.flat_map { |e| valid_triangle_pairs(e) }
    original_angles = triangle_pair_angles(triangle_pairs)
    start_simulation(edge)
    view.show_frame
    simulation_angles = triangle_pair_angles(triangle_pairs, true)

    changed_triangle_pairs = get_changed_triangle_pairs(triangle_pairs, original_angles, simulation_angles)

    rotation_axes = find_rotation_axes(changed_triangle_pairs)
    highlight_rotation_axes(rotation_axes)
    add_hinges(changed_triangle_pairs)
    reset_simulation
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
  end

  def reset_simulation
    @simulation.stop
    @simulation = nil
  end

  def create_actuator(edge, view)
    Sketchup.active_model.start_operation('toggle edge to actuator', true)
    edge.link_type = 'actuator'
    view.invalidate
    Sketchup.active_model.commit_operation
  end

  def valid_triangle_pairs(edge)
    edge.sorted_adjacent_triangle_pairs.select do |pair|
      pair.all? { |t| t.complete? && !t.contains_actuator? }
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

  def triangle_pair_angles(triangle_pairs, simulation = false)
    triangle_pairs.map do |t1, t2|
      if simulation
        n1 = simulation_triangle_normal(t1)
        n2 = simulation_triangle_normal(t2)
        n1.angle_between(n2)
      else
        t1.angle_between(t2)
      end
    end
  end

  def angle_changed?(angle, other_angle)
    (angle - other_angle).abs > MIN_ANGLE_DEVIATION
  end

  def get_changed_triangle_pairs(triangle_pairs, original_angles, simulation_angles)
    triangle_pairs.zip(original_angles, simulation_angles).flat_map do |p, oa, sa|
      if angle_changed?(oa, sa)
        [p]
      else
        []
      end
    end
  end

  def find_rotation_axes(triangle_pairs)
    edges = triangle_pairs.map { |t1, t2| t1.shared_edge(t2) }
    edges.uniq
  end

  def highlight_rotation_axes(edges)
    edges.each(&:highlight)
  end

  def add_hinges(triangle_pairs)
    triangle_pairs.each do |t1, t2|
      rotation_axis = t1.shared_edge(t2)
      [t1, t2].each do |triangle|
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