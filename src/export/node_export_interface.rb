require 'src/export/presets'
require 'src/export/hub_export_interface'
require 'src/export/hinge_export_interface'

# This class keeps track of hubs and hinges that will be exported.
# The hubs and hinges are associated with the node they are
# connected around.
# The logic which hinges have to be removed to create a printable
# node configuration is also included here.
class NodeExportInterface
  attr_accessor :node_hinge_map, :node_hub_map, :static_groups

  def initialize(static_groups)
    @node_hub_map = Hash.new { |h, k| h[k] = [] }
    @node_hinge_map = Hash.new { |h, k| h[k] = [] }
    @static_groups = static_groups
  end

  def add_hub(node, hub)
    @node_hub_map[node].push(hub)
  end

  def add_hinge(node, hinge)
    @node_hinge_map[node].push(hinge)
  end

  def hinges
    @node_hinge_map.values.flatten
  end

  def hinges_at_node(node)
    @node_hinge_map[node]
  end

  def mainhub_at_node(node)
    raise 'Node does not have a main hub' if @node_hub_map[node].empty?
    @node_hub_map[node][0]
  end

  def subhubs_at_node(node)
    @node_hub_map[node].drop(1)
  end

  def non_mainhub_edges_at_node(node)
    edges = Graph.instance.edges.values
    node_edges = edges.select { |edge| edge.nodes.include? node }
    return node_edges if @node_hub_map[node].empty?

    mainhub_edges = mainhub_at_node(node).edges
    node_edges.reject { |edge| mainhub_edges.include? edge }
  end

  def l1_at_node(node)
    l1 = hinges_at_node(node).map { |hinge| hinge.l1 }.max
    l1 = 0.0.mm if l1.nil?

    if subhubs_at_node(node).size > 0
      l1 = [l1, PRESETS::MINIMUM_L1].max
    end

    l1
  end

  def apply_hinge_algorithm
    @node_hinge_map.each do |node, hinges|
      new_hinges = filter_valid_hinges(hinges)
      new_hinges = filter_subhub_violations(node, new_hinges)
      new_hinges = order_hinges(new_hinges)
      @node_hinge_map[node] = new_hinges
    end
  end

  def elongate_edges
    Edge.enable_bottle_freeze

    nodes = Graph.instance.nodes.values

    # find out all edges that need to be elongated and their corresponding node
    elongation_tuples = []
    nodes.each do |node|
      # edges that are part of a subhub need to be elongated
      elongated_edges = non_mainhub_edges_at_node(node)
      # edges that are connected by hinges also need to be elongated
      elongated_edges += hinges_at_node(node).map { |hinge| [hinge.edge1, hinge.edge2] }.flatten
      elongated_edges.uniq!
      # don't elongated edges that have a dynamic size
      elongated_edges.reject! { |edge| edge.dynamic? }

      elongation_tuples.concat(elongated_edges.map { |edge| [node, edge] })
    end

    elongate_edges_with_tuples(elongation_tuples) unless elongation_tuples.empty?

    Edge.disable_bottle_freeze
  end

  private
  def filter_valid_hinges(hinges)
    new_hinges = hinges.clone

    loop do
      # save how many hinges each hinge shares an edge with around the current
      # node. if it is more than one hinge at either connection, hinges need
      # to be removed
      shared_a_hinge_count = {}
      shared_b_hinge_count = {}

      new_hinges.each do |hinge|
        shared_hinges_a = new_hinges.select do |other_hinge|
          hinge != other_hinge && other_hinge.edges.include?(hinge.edge1)
        end
        shared_a_hinge_count[hinge] = shared_hinges_a.size

        shared_hinges_b = new_hinges.select do |other_hinge|
          hinge != other_hinge && other_hinge.edges.include?(hinge.edge2)
        end
        shared_b_hinge_count[hinge] = shared_hinges_b.size
      end

      valid_result = new_hinges.all? do |hinge|
        shared_a_hinge_count[hinge] <= 1 && shared_b_hinge_count[hinge] <= 1
      end

      break if valid_result

      # assign values to hinges that states how likely it is to be removed
      # the higher number the number, the more problematic is a hinge
      hinge_values = []
      new_hinges.each do |hinge|
        connects_actuator = hinge.edge1.dynamic? || hinge.edge2.dynamic?

        val = 0
        val += shared_a_hinge_count[hinge] - 1 if shared_a_hinge_count[hinge] > 1
        val += shared_b_hinge_count[hinge] - 1 if shared_b_hinge_count[hinge] > 1
        val += 1 if hinge.is_double_hinge && !connects_actuator

        hinge_values.push([hinge, val])
      end

      hinge_values.sort! { |a, b| b[1] <=> a[1] }
      new_hinges.delete(hinge_values.first[0])
    end

    new_hinges
  end

  def filter_subhub_violations(node, hinges)
    # check that all subhubs are only connected to at most one hinge
    # remove hinges if there are more than one, starting with double hinges
    subhubs_at_node(node).each do |subhub|
      subhub.edges.each do |edge|
        edge_hinges = hinges.select { |hinge| hinge.edges.include?(edge) }
        edge_hinges.sort_by! { |hinge| hinge.is_double_hinge ? 0 : 1 }

        while edge_hinges.size > 1
          hinges.delete(edge_hinges.first)
          edge_hinges.delete(edge_hinges.first)
        end
      end
    end

    hinges
  end

  # make sure that edge1 is the unconnected one if there is one
  def align_first_hinge(hinges, cur_hinge)
    other_edges = (hinges - [cur_hinge]).flat_map do |hinge|
      [hinge.edge1, hinge.edge2]
    end

    is_edge1_connected = other_edges.include? cur_hinge.edge1
    is_edge2_connected = other_edges.include? cur_hinge.edge2

    raise 'Hinge is not connected to any other hinge' if !is_edge1_connected &&
      !is_edge2_connected

    cur_hinge.swap_edges if is_edge1_connected && !is_edge2_connected
  end

  # get the hinge that is connected to the least number of other hinges
  # this will be the start of the chain
  def get_first_hinge(hinges)
    sorted_hinges = hinges.sort do |h1, h2|
      h1.num_connected_hinges(hinges) <=> h2.num_connected_hinges(hinges)
    end
    sorted_hinges[0]
  end

  # orders hinges so that they form a chain:
  # the result will be arrays of hinges, where edge2 of a hinge and edge1
  # of the following hinge match, if they are connected
  def order_hinges(hinges)
    cur_hinge = get_first_hinge(hinges)
    if cur_hinge.num_connected_hinges(hinges) > 0
      align_first_hinge(hinges, cur_hinge)
    end

    new_hinges = []

    while new_hinges.size < hinges.size
      new_hinges.push(cur_hinge)

      break if new_hinges.size == hinges.size

      # check which hinges can connect to the current hinge B part
      next_hinge_possibilities = hinges.select do |hinge|
        hinge.edges.include?(cur_hinge.edge2) && !new_hinges.include?(hinge)
      end
      if next_hinge_possibilities.size > 1
        raise 'More than one next hinge can be connected at node ' +
                node.id.to_s
      end

      if next_hinge_possibilities.empty?
        remaining_hinges = hinges - new_hinges
        cur_hinge = get_first_hinge(remaining_hinges)
        if cur_hinge.num_connected_hinges(remaining_hinges) > 0
          align_first_hinge(remaining_hinges, cur_hinge)
        end

        next
      end

      next_hinge = next_hinge_possibilities[0]

      # make sure that B part of current hinge connects to
      # A part of next hinge
      next_hinge.swap_edges if cur_hinge.edge2 != next_hinge.edge1
      cur_hinge = next_hinge
    end

    new_hinges
  end

  def elongate_edges_with_tuples(elongation_tuple)
    l2 = PRESETS::L2
    l3_min = PRESETS::L3_MIN

    loop do
      relaxation = Relaxation.new
      is_finished = true

      elongation_tuple.each do |node, edge|
        # if pods are fixed and edge can not be elongated, raise error
        edge_fixed = edge.nodes.any?(&:fixed?)
        if edge_fixed
          raise "#{edge.inspect} is fixed, e.g. by a pod, but needs to be "\
                'elongated since a hinge connects to it.'
        end

        elongation = if edge.first_node?(node)
                       edge.first_elongation_length
                     else
                       edge.second_elongation_length
                     end

        l1 = l1_at_node(node)
        target_elongation = l1 + l2 + l3_min

        next if elongation >= target_elongation

        total_elongation = edge.first_elongation_length +
          edge.second_elongation_length
        relaxation.stretch_to(edge,
                              edge.length - total_elongation +
                                2 * target_elongation + 10.mm)
        is_finished = false
      end

      break if is_finished

      relaxation.relax
    end
  end
end
