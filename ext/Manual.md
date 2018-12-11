## TrussFab::Joint
This is an abstract class for all joints.

```ruby
valid?
destroy
group
world
parent
child

breaking_force
breaking_force=(value) # in Newtons
stiffness
stiffness=(value) # 0.0 - 1.0
solver_model
solver_model=(value) # 0 or 2
bodies_collidable
bodies_collidable=(state) # true/false

linear_tension
angular_tension

get_pin_transformation
get_pin_transformation2(mode)
set_pin_transformation(pin_matrix)
```


## TrussFab::Fixed < TrussFab::Joint

```ruby
# @param [TrussFab::World] world
# @param [TrussFab::Body, nil] parent
# @param [TrussFab::Body] child
# @param [Geom::Transformation] matrix pin dir
# @param [Sketchup::Group, Sketchup::ComponentInstance, nil] group
initialize(world, parent, child, matrix, group)
```


## TrussFab::PointToPoint < TrussFab::Joint

```ruby
# @param [TrussFab::World] world
# @param [TrussFab::Body, nil] parent
# @param [TrussFab::Body] child
# @param [Geom::Point3d] pt1
# @param [Geom::Point3d] pt2
# @param [Sketchup::Group, Sketchup::ComponentInstance, nil] group
initialize(world, parent, child, pt1, pt2, group)

get_point1
set_point1(point)
get_point2
set_point2(point)
start_distance
start_distance=(value) # in meters
cur_distance # in meters
cur_normal
```


## TrussFab::PointToPointActuator < TrussFab::Joint

```ruby
# @param [TrussFab::World] world
# @param [TrussFab::Body, nil] parent
# @param [TrussFab::Body] child
# @param [Geom::Point3d] pt1
# @param [Geom::Point3d] pt2
# @param [Sketchup::Group, Sketchup::ComponentInstance, nil] group
initialize(world, parent, child, pt1, pt2, group)

get_point1
set_point1(point)
get_point2
set_point2(point)
start_distance
start_distance=(value) # in meters
rate
rate=(value) # in m/s
reduction_ratio
reduction_ratio=(value) # 0.0 - 1.0
power
power=(value) # power to apply; pass zero to use maximum power
controller
controller=(value) # desired position (in meters) with respect to start_distance
cur_distance # in meters
cur_velocity # in m/s
cur_normal
```


## TrussFab::PointToPointGasSpring < TrussFab::Joint

```ruby
# @param [TrussFab::World] world
# @param [TrussFab::Body, nil] parent
# @param [TrussFab::Body] child
# @param [Geom::Point3d] pt1
# @param [Geom::Point3d] pt2
# @param [Sketchup::Group, Sketchup::ComponentInstance, nil] group
initialize(world, parent, child, pt1, pt2, group)

get_point1
set_point1(point)
get_point2
set_point2(point)
extended_length
extended_length=(value) # in meters
stroke_length
stroke_length=(value) # in meters
extended_force
extended_force=(value) # in Newtons
threshold
threshold=(value) # min barrier in (meters) when the joint is fully contracted; this limits maximum force
damp
damp=(value) # in kg/s
cur_length # in meters
cur_velocity # in m/s
cur_normal
update_info # call this whenever setting linked body static/dynamic while running simulation
```


## TrussFab::GenericPointToPoint < TrussFab::Joint

```ruby
# @param [TrussFab::World] world
# @param [TrussFab::Body, nil] parent
# @param [TrussFab::Body] child
# @param [Geom::Point3d] pt1
# @param [Geom::Point3d] pt2
# @param [Sketchup::Group, Sketchup::ComponentInstance, nil] group
initialize(world, parent, child, pt1, pt2, group)

get_point1
set_point1(point)
get_point2
set_point2(point)
min_distance
min_distance=(value) # in meters
max_distance
max_distance=(value) # in meters
force
force=(value) # in Newtons
cur_distance # in meters
cur_velocity # in m/s
cur_normal
limits_enabled?
limits_enabled=(state) # Turn on/off min/max distance limits
update_info # call this whenever setting linked body static/dynamic while running simulation
```


## TrussFab::Plane < TrussFab::Joint

```ruby
# @param [TrussFab::World] world
# @param [TrussFab::Body, nil] parent
# @param [TrussFab::Body] child
# @param [Geom::Transformation] matrix pin dir
# @param [Sketchup::Group, Sketchup::ComponentInstance, nil] group
initialize(world, parent, child, matrix, group)

linear_friction
linear_friction=(value)
angular_friction
angular_friction=(value)
rotation_allowed?
rotation_allowed=(state)
```
