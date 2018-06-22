require 'src/export/presets'
require 'src/export/hub_export_interface'
require 'src/export/hinge_export_interface'

# This class keeps track of hubs and hinges that will be exported.
# The hubs and hinges are associated with the node they are
# connected around.
# The logic which hinges have to be removed to create a 3D printable
# node configuration is also included here.
class NodeExportInterface
  attr_reader :node_hinge_map, :node_hub_map, :static_groups

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

  def subhubs
    @node_hub_map.values.map { |hubs| hubs.drop(1) }.flatten
  end

  def hinges_at_node(node)
    @node_hinge_map[node]
  end

  def hubs_at_node(node)
    @node_hub_map[node]
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
    l1 = hinges_at_node(node).map(&:l1).max
    l1 = 0.0.mm if l1.nil?
    l1 = [l1, PRESETS::MINIMUM_L1].max if subhubs_at_node(node).any?

    l1
  end

  def apply_hinge_algorithm
    @node_hinge_map.each do |node, hinges|
      hubs = hubs_at_node(node)
      new_parts = filter_valid_parts(node, hubs, hinges)

      new_hinges = new_parts.select { |part| part.is_a? HingeExportInterface }
      new_hinges = order_hinges(new_hinges)
      @node_hinge_map[node] = new_hinges

      new_hubs = new_parts.select { |part| part.is_a? HubExportInterface }
      @node_hub_map[node] = new_hubs
    end
  end

  def elongate_edges
    Edge.enable_bottle_freeze

    nodes = Graph.instance.nodes.values

    # find out all edges that need to be elongated and their corresponding node
    elongated_edge_map = Hash.new { |h, k| h[k] = Set.new }
    nodes.each do |node|
      # edges that are part of a subhub need to be elongated
      elongated_edges = subhubs_at_node(node).map { |hub| hub.edges }.flatten
      # edges that are connected by hinges also need to be elongated
      elongated_edges += hinges_at_node(node)
                         .map { |hinge| [hinge.edge1, hinge.edge2] }.flatten
      elongated_edges.uniq!
      # don't elongated edges that have a dynamic size
      elongated_edges.reject!(&:dynamic?)

      elongated_edges.each { |edge| elongated_edge_map[edge].add(node) }
    end

    elongate_edges_with_tuples(elongated_edge_map)

    Edge.disable_bottle_freeze
  end

  private

  def find_adjacent_parts(part, parts)
    parts.select do |other_part|
      part != other_part && (part.edges & other_part.edges).any?
    end
  end

  def find_violating_parts(parts)
    violating_parts = []

    parts.each do |part|
      violating = false

      part.edges.each do |edge|
        connected_part_count = parts.count do |other_part|
          part != other_part && other_part.edges.include?(edge)
        end

        if connected_part_count > 1
          violating = true
          break
        end
      end

      violating_parts.push(part) if violating
    end

    violating_parts
  end

  def depth_first_search(parts)
    remaining = [parts[0]]
    discovered = Set.new

    while remaining.any?
      current = remaining.pop
      next if discovered.include?(current)
      discovered.add(current)
      find_adjacent_parts(current, parts).each do |adjacent_part|
        remaining.push(adjacent_part)
      end
    end

    discovered
  end

  def check_part_connectedness(parts)
    parts.size == depth_first_search(parts).size
  end

  def filter_valid_parts(node, hubs, hinges)
    mainhub = hubs[0]
    all_parts = hubs + hinges
    violating_parts = find_violating_parts(all_parts)
    # mainhub can not be removed, therefore it can not be considered violating
    violating_parts.delete(mainhub)

    # Enumerate all possible combinations of parts to remove, starting with
    # the least amount of parts, since we want to test bigger remaining sets
    # earlier.
    removal_possibilities_enumerator = Enumerator.new do |y|
      cur_length = 0
      while cur_length <= violating_parts.size
        violating_parts.combination(cur_length).each do |combination|
          y << combination
        end
        cur_length += 1
      end
    end

    # Go through all possible combinations of violating parts and remove them.
    # If the remaining parts
    #   (1) don't contain violating parts anymore
    #   (2) are still fully connected
    # a valid result was found.
    removal_possibilities_enumerator.each do |removal_possibility|
      remaining_parts = all_parts - removal_possibility

      has_violating_part = find_violating_parts(remaining_parts).any?
      is_connected = check_part_connectedness(remaining_parts)

      return remaining_parts if is_connected && !has_violating_part
    end

    raise 'No valid hinge configuration could be found at node ' + node.id.to_s
  end

  # make sure that edge1 is the unconnected one if there is one
  def align_first_hinge(hinges, cur_hinge)
    other_edges = (hinges - [cur_hinge]).flat_map do |hinge|
      [hinge.edge1, hinge.edge2]
    end

    is_edge1_connected = other_edges.include? cur_hinge.edge1
    is_edge2_connected = other_edges.include? cur_hinge.edge2

    if !is_edge1_connected && !is_edge2_connected
      raise 'Hinge is not connected to any other hinge'
    end

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

  def elongate_edges_with_tuples(elongated_edge_map)
    l2 = PRESETS::L2
    l3_min = PRESETS::L3_MIN

    loop do
      relaxation = Relaxation.new
      is_finished = true

      elongated_edge_map.each do |edge, nodes|
        # if pods are fixed and edge can not be elongated, raise error
        edge_fixed = edge.nodes.any?(&:fixed?)
        if edge_fixed
          raise "#{edge.inspect} is fixed, e.g. by a pod, but needs to be "\
                'elongated since a hinge connects to it.'
        end

        new_first_elongation_length = edge.first_elongation_length
        new_second_elongation_length = edge.second_elongation_length

        nodes.each do |node|
          l1 = l1_at_node(node)
          target_elongation = l1 + l2 + l3_min

          if node == edge.first_node
            new_first_elongation_length = target_elongation
          elsif node == edge.second_node
            new_second_elongation_length = target_elongation
          else
            raise 'Logic error during node export: '\
                  'node is not connected to edge'
          end
        end

        next if new_first_elongation_length <= edge.first_elongation_length &&
                new_second_elongation_length <= edge.second_elongation_length

        total_old_elongation =
          edge.first_elongation_length + edge.second_elongation_length

        total_new_elongation =
          new_first_elongation_length + new_second_elongation_length

        edge.link.elongation_ratio =
          new_first_elongation_length / total_new_elongation

        relaxation.stretch_to(edge,
                              edge.length - total_old_elongation +
                                total_new_elongation + 10.mm)

        is_finished = false
      end

      break if is_finished

      relaxation.relax
    end
  end
end
