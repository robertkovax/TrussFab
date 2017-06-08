
class Animation

  def initialize
    @counter = 0
    @node = Graph.instance.nodes.values[0]
    @world_address = MSPhysics::Newton::World.create(1)
    collision = MSPhysics::Newton::Collision.create_box(@world_address, 0.1, 0.1, 0.1, 0, nil)

    material_id = MSPhysics::Newton::World.get_default_material_id(@world_address)

    @body_address = MSPhysics::Newton::Body.create_dynamic(@world_address,
                                                           collision,
                                                           @node.thingy.entity.transformation,
                                                           material_id,
                                                           @node.thingy.entity)

    @last_frame_time = Time.now
  end

  def nextFrame(view)
    # puts 'next frame'
    MSPhysics::Newton::Body.set_force(@body_address, [0,0,1])

    now = Time.now
    delta = now - @last_frame_time
    @last_frame_time = now
    MSPhysics::Newton::World.update(@world_address, delta)
    
    position =  MSPhysics::Newton::Body.get_position(@body_address, 0.to_i)
    @node.move(position)
    # puts MSPhysics::Newton::Body.get_force(@body_address)
    # puts position
    @counter += 1
    @counter <= 30
  end
end

Sketchup.active_model.active_view.animation = Animation.new