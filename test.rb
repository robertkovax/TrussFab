require 'sketchup.rb'
# require 'lib/ams_Lib/main.rb'
# require 'lib/ams_Lib/geometry.rb'
# require 'lib/ams_Lib/group.rb'
require 'lib/MSPhysics/main.rb'

class Animation

  def initialize
    @counter = 0
    @node = Graph.instance.nodes.values[0]

    @world = MSPhysics::World.new
    @body = create_body_for(@node)

    @last_frame_time = Time.now
  end

  def create_body_for(node)
    MSPhysics::Body.new(@world, node.thingy.entity, :convex_hull)
  end

  def nextFrame(_view)
    @body.set_force([0,0,1])

    now = Time.now
    delta = now - @last_frame_time
    @last_frame_time = now
    @world.update(delta)


    position =  @body.get_position()
    @node.move(position)
    # puts MSPhysics::Newton::Body.get_force(@body_address)
    # puts position
    @counter += 1
    @counter <= 30
  end

end

Sketchup.active_model.active_view.animation = Animation.new