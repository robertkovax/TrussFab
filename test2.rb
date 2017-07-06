require 'lib/MSPhysics/main.rb'
require 'set'
require 'src/thingies/link_entities/bottle_link.rb'
require 'src/simulation/simulation_helper.rb'

class Animation
	include Singleton

	attr_accessor :group, :nodes, :edges, :value, :piston, :upper

	LINE_STIPPLE = ''.freeze

	def initialize
		@counter = 0
		@frame = 0

		@last_frame = 0
		@last_time = 0


		@world = MSPhysics::World.new
		# @world.set_gravity(0, 0, 0)
		@bodies = {}

		@ground_body = add_ground
		# @node_body = create_body_for(@node)
		# @edge_body = create_body_for(@edge)

		# @nodes_bodies = create_bodies(Graph.instance.nodes.values)
		# @node_body = @nodes_bodies.values[0]
		# connect_all_fixed(Graph.instance.nodes.values)

		# @transformation = Geom::Transformation.new
		# connected_nodes = connected_component(@node)
		# @group = create_group(connected_nodes)
		# @group_body = create_body(@group)

		# connect_tetra2(@nodes)


		@value = nil
		@running = true

		# @last_transformation = @initial_transformation = @group.transformation


		@last_frame_time = Time.now
	end

	def setup

		# create entities
	    model = ModelStorage.instance.models['hard']
	    model = model.longest_model
		entity1 = BottleLink.new([0,0,0], Geom::Vector3d.new([1,1,1]), model.definition).entity
		entity2 = BottleLink.new([0,0,0], Geom::Vector3d.new([1,2,2]), model.definition).entity
		entity3 = BottleLink.new([0,0,0], Geom::Vector3d.new([1,3,3]), model.definition).entity

		# create all bodies
		[entity1, entity2, entity3].each do |entity|
			body = MSPhysics::Body.new(@world, entity, :convex_hull)
			body.collidable = true
			body.mass = 0.1
			body.static = false
			puts body.linear_damping
			body.linear_damping=(1.0)

		# create joints
		# edge.create_joints(@world)
		end

		# actuator = Graph.instance.edges.values.find { |edge| edge.link_type == 'actuator' }
		# unless actuator.nil?
		# 	@piston = actuator.thingy.piston
		# 	piston_dialog
		# end
	end

	def add_ground
		group = Sketchup.active_model.entities.add_group()
		x = y = 10_000
		z = -1
		pts = []
		pts[0] = [-x, -y, z]
		pts[1] = [x, -y, z]
		pts[2] = [x, y, z]
		pts[3] = [-x, y, z]
		face = group.entities.add_face(pts)
		face.pushpull(-1)
		face.visible = false
		body = MSPhysics::Body.new(@world, group, :convex_hull)
		body.static = true
		body
	end

	def update_world
		now = Time.now
		@delta = now - @last_frame_time
		@last_frame_time = now
		@world.update(@delta)
	end

	def show_force(body, view)
		force = Geom::Vector3d.new(*body.get_force)
		force = Geometry.scale(force, 10)
		position = body.get_position(1)
		second_position = position + force
		view.line_stipple = LINE_STIPPLE
		view.drawing_color = 'black'
		view.line_width = 10
		view.draw_lines(position, second_position)
		# puts position
		# puts view
	end

	def draw_forces(view)
		MSPhysics::Body.all_bodies.each do |body|
			show_force(body, view)
		end
	end
	def nextFrame(view)
		# force on whole body
		# @group_body.set_force([0, 0, 1000])



		# force applied at specific point
		# point = @node.position
		# @group_body.add_point_force(point, [0, 0, 100])


		# log_time('update world') {
		update_world
		# }

		# log_time('update group position') {
		MSPhysics::Body.all_bodies.each do |body|
			body.group.move!(body.get_matrix) if body.matrix_changed?
		end
		# }
		@frame += 1
		if @frame % 20 == 0
			delta_frame = @frame - @last_frame
			now = Time.now.to_f
			delta_time = now - @last_time
			@fps = (delta_frame / delta_time).to_i
			Sketchup.status_text = "Frame: #{@frame}   Time: #{sprintf("%.2f", @world.time)} s   FPS: #{@fps}"
			@last_frame = @frame
			@last_time = now
		end

		view.show_frame
		@running
	end

	def halt
		@running = false
	end

end

def animate
	animation = Animation.instance
	animation.setup
	Sketchup.active_model.active_view.animation = animation
	animation
end


