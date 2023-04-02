require 'src/tubes_and_ties/tube_edge.rb'
require 'src/tubes_and_ties/tube_node.rb'

class TubeGraph
  Interval = Struct.new(:first_occurence, :last_occurence)

  attr_accessor :edges, :nodes

  class << self
    # ensure that your constructor can't be called from the outside
    protected :new

    def from_graph(graph)
      tube_graph = TubeGraph.new
      graph.nodes.each do |node_id, node|
        tube_node = TubeNode.new(node_id)
        tube_graph.nodes[node_id] = tube_node
      end

      graph.edges.each do |edge_id, edge|
        first_node = tube_graph.nodes[edge.first_node.id]
        second_node = tube_graph.nodes[edge.second_node.id]
        tube_edge = TubeEdge.new(first_node, second_node, edge_id)
        first_node.edges.push(tube_edge)
        second_node.edges.push(tube_edge)
        tube_edge.marked_as_double = edge.link.marked_as_double
        tube_graph.edges[edge_id] = tube_edge
      end
      tube_graph
    end
  end

  def initialize
    @edges = {} # {(id => edge)}
    @nodes = {} # {(id => node)}

    @euler_path = []
  end

  def find_soft_euler_path
    @euler_path = []
    id, node = @nodes.to_a.last
    euler_for_real(node)

    @euler_path.each_cons(2) do |node_a, node_b|
      puts "#{node_a.edge_to(node_b).id}, (#{node_a.id}, #{node_b.id})"
    end
    puts "-------"

    #
    # tube_depth_first_search(node)
    puts @euler_path.map(&:id)
    puts "-------"


    # Calculate slot useage
    slot_usage
    @euler_path
  end

  def tube_depth_first_search(node)
    # color[v] = gray
    node.adjacent_nodes_without_first_mark.each do |u|
      node.edge_to(u).first_mark = true
      tube_depth_first_search(u)
      # color[v] = black
    end
    @euler_path.push(node)
  end

  def euler_iteratively(start)
    @euler_path = []
    st = [start]
    until st.empty?
      v = st[-1]
      if v.edges_without_first_mark.empty?
        @euler_path.push(v)
        st.pop
      else
        edge = v.edges_without_first_mark[0]
        edge.first_mark = true
        st.push(edge.opposite(v))
      end

    end

    # stack St;
    # put start vertex in St;
    # until St is empty
    #   let V be the value at the top of St;
    #   if degree(V) = 0, then
    #     add V to the answer;
    #     remove V from the top of St;
    #   otherwise
    #     find any edge coming out of V;
    #     remove it from the graph;
    #     put the second end of this edge in St;
  end

  def euler_for_real(start)
    @euler_path = [start]
    # until every edge has been visited once...
    until @edges.keys.all? {|edge_id| @edges[edge_id].first_mark  }
      v = @euler_path[-1]

      if (v.edges_with_user_mark - v.edges_with_second_mark).length > 0
        edge = (v.edges_with_user_mark - v.edges_with_second_mark)[0]
        if  !edge.first_mark
          edge.first_mark = true
        else
          edge.second_mark = true
        end
      else
        if v.edges_without_first_mark.length > 0
          u = double_dfs(v)
          edge = u.edge_to(v)
          edge.first_mark = true
        elsif v.edges_without_second_mark.length > 0
          u = double_dfs_second(v)
          edge = u.edge_to(v)
          edge.second_mark = true
        else
          puts "error..."
        end
      end
      @euler_path.push(edge.opposite(v))
    end
  end

  # should we do bfs?!
  def double_dfs(node)
    visited = [node]
    n = node.adjacent_nodes_without_first_mark
    n.sort_by! { |node| node.edges_without_first_mark.length}
    neighbours = n.map(&:id)
    path = neighbours.compact
    q = neighbours.compact
    visited.concat(neighbours.compact)
    puts("dfs for node #{node.id}: neighbours: #{q}")
    until q.empty?
      v = @nodes[q.shift]
      puts("    current node #{v.id}")
      puts("            path #{path}")
      pre = @nodes[path.shift]
      if (@euler_path.include?(v) && v.open) || @euler_path.length == 1
        return pre
      end
      nodes = v.adjacent_nodes_without_first_mark.reject { |node| visited.include?(node.id) }
      nodes.sort_by! { |node| node.edges_without_first_mark.length}
      node_ids = nodes.map(&:id)
      q.concat(node_ids.compact)
      path.concat(Array.new(node_ids.length, pre.id))
      visited.concat(node_ids.compact)
      puts("    current node #{v.id}: q: #{q}")
    end
  end

  def double_dfs_second(node)
    visited = [node]
    n = node.adjacent_nodes_without_second_mark
    n.sort_by! { |node| node.edges_without_second_mark.length}
    neighbours = n.map(&:id)
    path = neighbours.compact
    q = neighbours.compact
    visited.concat(neighbours.compact)
    puts("double dfs for node #{node.id}: neighbours: #{q}")
    until q.empty?
      v = @nodes[q.shift]
      puts("    current node #{v.id}")
      puts("            path #{path}")
      pre = @nodes[path.shift]
      if @euler_path.include?(v) && v.open
        return pre
      end
      nodes = v.adjacent_nodes_without_second_mark.reject { |node| visited.include?(node.id) }
      nodes.sort_by! { |node| node.edges_without_second_mark.length}
      node_ids = nodes.map(&:id)
      q.concat(node_ids.compact)
      path.concat(Array.new(node_ids.length, pre.id))
      visited.concat(node_ids.compact)
      puts("    current node #{v.id}: q: #{q}")
    end
  end

  def slot_usage
    intervals = {}
    @euler_path.each { |node| intervals[node.id] = Interval.new(first_occurence_in_path(node), last_occurence_in_path(node)) }
    @euler_path.each { |node| puts("node #{node.id}: (#{intervals[node.id].first_occurence}, #{intervals[node.id].last_occurence})")  }


    # capacity = Array.new(@euler_path.length, 0)
    slot_count = 0
    max_slot_count = 0
    # ... calculate max slot capacity
    node_ids = @euler_path.map(&:id)
    node_ids.each_with_index do |node_id, index|
      # intervals.each do |node, value|
      #
      # end
      occurences = intervals[node_id]
      if (index == occurences.first_occurence)
        slot_count += 1
      elsif (index == occurences.last_occurence)
        slot_count -= 1
      end
      if (slot_count > max_slot_count)
        max_slot_count = slot_count
      end
    end
    puts "max slots: #{max_slot_count}"

  end

  def first_occurence_in_path(node)
    @euler_path.find_index(node)
  end

  def last_occurence_in_path(node)
    @euler_path.rindex(node)
  end

end
