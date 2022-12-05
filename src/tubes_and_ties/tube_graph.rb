require 'src/tubes_and_ties/tube_edge.rb'
require 'src/tubes_and_ties/tube_node.rb'

class TubeGraph
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
    id, node = @nodes.first
    euler_iteratively(node)
    # tube_depth_first_search(node)
    puts @euler_path.map { |node| node.id }
    puts "-------"
    @euler_path.each_cons(2) do |node_a, node_b|
      puts node_a.edge_to(node_b).id
    end
    puts "-------"
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

end
