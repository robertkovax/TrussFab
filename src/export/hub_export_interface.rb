class HubExportInterface
  attr_reader :edges, :hinge_edge

  def initialize(edges)
    @edges = edges
    @hinge_edge = nil
  end

  def hinging?
    @hinge_edge != nil
  end

  def set_hinge_edge(edge)
    @hinge_edge = edge
  end
end
