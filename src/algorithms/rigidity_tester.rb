require 'matrix'

class RigidityTester

  # expects an array of edges that make up a connected_component
  def self.rigid?(edges)
    #disabled for now, because it causes bugs on bigger structures
    return false
    nodes = Set.new
    proto_matrix = edges.map do |edge|
      [edge.first_node, edge.second_node].map do |node|
        nodes.add(node.id)
        other_node = edge.other_node(node)
        hash = { id: node.id, vec: node.position - other_node.position }
        hash
      end
    end
    # the rank of the matrix has to be higher than the number of degrees of freedom (DOF) internal to the structure
    # (which implies subtracting the 6 DOF that result from moving and rotating the whole structure)
    rigidity_condition = nodes.size * 3 - 6
    # fail early as the rows are one limiting factor for the rank of the matrix
    return false if edges.size < rigidity_condition

    matrix_base = Array.new(proto_matrix.size) do |index|
      # initialize the row with 0
      arr = Array.new(nodes.size * 3, 0.to_int)
      proto_row = proto_matrix[index]
      # set the values of both of the nodes' positions
      proto_row.each do |hash|
        id, vec = hash.values_at(:id, :vec)
        node_index = nodes.find_index(id)
        arr[node_index * 3] = vec.x.to_int
        arr[node_index * 3 + 1] = vec.y.to_int
        arr[node_index * 3 + 2] = vec.z.to_int
      end
      arr
    end
    matrix = Matrix.rows(matrix_base, false)
    rank = matrix.rank
    rank >= rigidity_condition
  end
end
