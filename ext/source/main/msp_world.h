/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_WORLD_H
#define MSP_WORLD_H

#include "msp.h"

class MSP::World {
public:
    // Constants
    static const treal DEFAULT_GRAVITY_X;
    static const treal DEFAULT_GRAVITY_Y;
    static const treal DEFAULT_GRAVITY_Z;
    static const treal DEFAULT_WIND_X;
    static const treal DEFAULT_WIND_Y;
    static const treal DEFAULT_WIND_Z;
    static const treal MIN_TOUCH_DISTANCE;
    static const treal MIN_TIMESTEP;
    static const treal MAX_TIMESTEP;
    static const treal DEFAULT_TIMESTEP;
    static const treal CONTACT_MERGE_TOLERANCE;
    static const treal MATERIAL_THICKNESS;
    static const treal MATERIAL_STATIC_FRICTION_COEF;
    static const treal MATERIAL_KINETIC_FRICTION_COEF;
    static const treal MATERIAL_ELASTICITY;
    static const treal MATERIAL_SOFTNESS;
    static const treal DEFAULT_DRAG_COEFFICIENT;
    static const treal DEFAULT_DAMP_COEFFICIENT;
    static const treal MIN_COL_SIZE;
    static const treal MAX_COL_SIZE;
    static const int DEFAULT_SOLVER_MODEL;

    // Structures
    struct Data {
        NewtonWorld* m_world;
        VALUE v_self;
        treal m_elapsed_time;
        treal m_timestep;
        treal m_timestep_inv;
        treal m_material_thickness;
        treal m_drag_coef;
        treal m_damp_coef;
        int m_material_id;
        int m_material_id_nc;
        int m_max_threads;
        int m_solver_model;
        Geom::Vector3d m_gravity;
        Geom::Vector3d m_wind_velocity;
        std::map<const NewtonCollision*, CollisionData*> m_collisions;
        std::map<const NewtonBody*, VALUE> m_bodies;
        std::map<const NewtonJoint*, VALUE> m_joints;
        std::set<VALUE> m_gears;
        std::set<const NewtonBody*> m_magnets;
        std::set<DelayedForceAndTorque*> m_dfts;
        std::vector<const NewtonJoint*> m_joints_to_destroy;

        Data() :
            m_elapsed_time(0.0f),
            m_timestep(DEFAULT_TIMESTEP),
            m_timestep_inv((treal)(1.0) / DEFAULT_TIMESTEP),
            m_material_thickness(MATERIAL_THICKNESS),
            m_drag_coef(DEFAULT_DRAG_COEFFICIENT),
            m_damp_coef(DEFAULT_DAMP_COEFFICIENT),
            m_solver_model(DEFAULT_SOLVER_MODEL),
            m_gravity(DEFAULT_GRAVITY_X * M_METER_TO_INCH, DEFAULT_GRAVITY_Y * M_METER_TO_INCH, DEFAULT_GRAVITY_Z * M_METER_TO_INCH),
            m_wind_velocity(DEFAULT_WIND_X * M_METER_TO_INCH, DEFAULT_WIND_Y * M_METER_TO_INCH, DEFAULT_WIND_Z * M_METER_TO_INCH)
        {
            m_world = nullptr;
            v_self = Qnil;
        }
    };

    // Helper Functions
    static VALUE c_class_allocate(VALUE klass);
    static void c_class_mark(void* data);
    static void c_class_deallocate(void* data);
    static Data* c_to_data(VALUE v_world);
    static Data* c_to_data(const NewtonWorld* world);
    static Data* c_to_data_simple_cast(VALUE v_world);
    static Data* c_to_data_type_check(VALUE v_world);
    static const NewtonBody* c_value_to_body(Data* world_data, VALUE v_body);
    static const NewtonJoint* c_value_to_joint(Data* world_data, VALUE v_body);
    static const NewtonCollision* c_value_to_collision(Data* world_data, VALUE v_collision);
    static const NewtonCollision* c_value_to_collision2(Data* world_data, VALUE v_collision);
    static VALUE c_collision_to_value(const NewtonCollision* collision);
    static void c_process_magnets(Data* world_data);
    static void c_advance(Data* world_data);

    // Callback Functions
    static void destructor_callback(const NewtonWorld* const world);

    static void collision_copy_constructor_callback(const NewtonWorld* const world, NewtonCollision* const collision, const NewtonCollision* const source_collision);
    static void collision_destructor_callback(const NewtonWorld* const world, const NewtonCollision* const collision);

    static int aabb_overlap_callback(const NewtonJoint* const contact, dFloat timestep, int thread_index);
    static int compound_aabb_overlap_callback(const NewtonJoint* const contact, dFloat timestep, const NewtonBody* const body0, const void* const collision_node0, const NewtonBody* const body1, const void* const collision_node1, int thread_index);
    static void contact_callback(const NewtonJoint* const contact_joint, treal timestep, int thread_index);

    static unsigned ray_prefilter_callback(const NewtonBody* const body, const NewtonCollision* const collision, void* const user_data);
    static unsigned ray_prefilter_callback_continuous(const NewtonBody* const body, const NewtonCollision* const collision, void* const user_data);
    static treal ray_filter_callback(const NewtonBody* const body, const NewtonCollision* const shape_hit, const treal* const hit_contact, const treal* const hit_normal, dLong collision_id, void* const user_data, treal intersect_param);
    static treal continuous_ray_filter_callback(const NewtonBody* const body, const NewtonCollision* const shape_hit, const treal* const hit_contact, const treal* const hit_normal, dLong collision_id, void* const user_data, treal intersect_param);

    static int body_iterator(const NewtonBody* const body, void* const user_data);

    static void draw_collision_iterator(void* const user_data, int vertex_count, const treal* const face_array, int face_id);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self);

    static VALUE rbf_is_valid(VALUE self);
    static VALUE rbf_destroy(VALUE self);

    static VALUE rbf_get_max_possible_threads_count(VALUE self);
    static VALUE rbf_get_max_threads_count(VALUE self);
    static VALUE rbf_set_max_threads_count(VALUE self, VALUE v_count);
    static VALUE rbf_get_cur_threads_count(VALUE self);

    static VALUE rbf_get_elapsed_time(VALUE self);
    static VALUE rbf_advance(VALUE self);
    static VALUE rbf_advance_by(VALUE self, VALUE v_time);

    static VALUE rbf_update_group_transformations(VALUE self);

    static VALUE rbf_get_bodies(VALUE self);
    static VALUE rbf_get_joints(VALUE self);
    static VALUE rbf_get_gears(VALUE self);

    static VALUE rbf_count_bodies(VALUE self);
    static VALUE rbf_count_joints(VALUE self);
    static VALUE rbf_count_gears(VALUE self);

    static VALUE rbf_find_body_by_group(VALUE self, VALUE v_group);
    static VALUE rbf_find_joint_by_group(VALUE self, VALUE v_group);
    static VALUE rbf_find_joints_by_group(VALUE self, VALUE v_group);

    static VALUE rbf_get_gravity(VALUE self);
    static VALUE rbf_set_gravity(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_get_wind_velocity(VALUE self);
    static VALUE rbf_set_wind_velocity(int argc, VALUE* argv, VALUE self);

    static VALUE rbf_get_update_timestep(VALUE self);
    static VALUE rbf_set_update_timestep(VALUE self, VALUE v_timestep);
    static VALUE rbf_get_solver_model(VALUE self);
    static VALUE rbf_set_solver_model(VALUE self, VALUE v_model);
    static VALUE rbf_get_material_thickness(VALUE self);
    static VALUE rbf_set_material_thickness(VALUE self, VALUE v_thinkness);

    static VALUE rbf_get_drag_coefficient(VALUE self);
    static VALUE rbf_set_drag_coefficient(VALUE self, VALUE v_coef);
    static VALUE rbf_get_damp_coefficient(VALUE self);
    static VALUE rbf_set_damp_coefficient(VALUE self, VALUE v_coef);

    static VALUE rbf_ray_cast(VALUE self, VALUE v_point1, VALUE v_point2);
    static VALUE rbf_continuous_ray_cast(VALUE self, VALUE v_point1, VALUE v_point2);
    static VALUE rbf_convex_ray_cast(VALUE self, VALUE v_body, VALUE v_matrix, VALUE v_target);
    static VALUE rbf_continuous_convex_ray_cast(VALUE self, VALUE v_body, VALUE v_matrix, VALUE v_target, VALUE v_max_hits);

    static VALUE rbf_draw_collision_wireframe(VALUE self, VALUE v_view, VALUE v_view_bb, VALUE v_sleep_color, VALUE v_active_color, VALUE v_line_width, VALUE v_line_stipple);
    static VALUE rbf_draw_collision_wireframe2(VALUE self, VALUE v_scale, VALUE v_view, VALUE v_view_bb, VALUE v_color, VALUE v_line_width, VALUE v_line_stipple);
    static VALUE rbf_draw_centre_of_mass(VALUE self, VALUE v_view, VALUE v_view_bb, VALUE v_scale, VALUE v_xaxis_color, VALUE v_yaxis_color, VALUE v_zaxis_color, VALUE v_line_width, VALUE v_line_stipple);

    static VALUE rbf_get_aabb(VALUE self);
    static VALUE rbf_get_bodies_in_aabb(VALUE self, VALUE v_bb);

    static VALUE rbf_apply_blast_impulse(VALUE self, VALUE v_center, VALUE v_radius, VALUE v_impulse);
    static VALUE rbf_apply_aero_blast_impulse(VALUE self, VALUE v_center, VALUE v_radius, VALUE v_impulse);
    static VALUE rbf_apply_buoyancy(VALUE self, VALUE v_bb, VALUE v_plane_origin, VALUE v_plane_normal, VALUE v_density, VALUE v_linear_viscosity, VALUE v_angular_viscosity, VALUE v_linear_current, VALUE v_angular_current);

    static VALUE rbf_get_touch_data_at(VALUE self, VALUE v_index);
    static VALUE rbf_get_touch_data_count(VALUE self);
    static VALUE rbf_get_touching_data_at(VALUE self, VALUE v_index);
    static VALUE rbf_get_touching_data_count(VALUE self);
    static VALUE rbf_get_untouch_data_at(VALUE self, VALUE v_index);
    static VALUE rbf_get_untouch_data_count(VALUE self);

    static VALUE rbf_create_null_collision(VALUE self);
    static VALUE rbf_create_box_collision(VALUE self, VALUE v_width, VALUE v_height, VALUE v_depth, VALUE v_offset_matrix);
    static VALUE rbf_create_sphere_collision(VALUE self, VALUE v_radius, VALUE v_offset_matrix);
    static VALUE rbf_create_scaled_sphere_collision(VALUE self, VALUE v_width, VALUE v_height, VALUE v_depth, VALUE v_offset_matrix);
    static VALUE rbf_create_cone_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_scaled_cone_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_cylinder_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_scaled_cylinder_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_capsule_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_scaled_capsule_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_total_height, VALUE v_offset_matrix);
    static VALUE rbf_create_tapered_capsule_collision(VALUE self, VALUE v_radius0, VALUE v_radius1, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_tapered_cylinder_collision(VALUE self, VALUE v_radius0, VALUE v_radius1, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_chamfer_cylinder_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_scaled_chamfer_cylinder_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_height, VALUE v_offset_matrix);
    static VALUE rbf_create_convex_hull_collision(VALUE self, VALUE v_vertices, VALUE v_tolerance, VALUE v_offset_matrix);
    static VALUE rbf_create_compound_collision(VALUE self, VALUE v_convex_collisions);
    static VALUE rbf_create_static_mesh_collision(VALUE self, VALUE v_polygons, VALUE v_optimize);
    static VALUE rbf_create_scene_collision(VALUE self, VALUE v_collisions);
    static VALUE rbf_is_collision_valid(VALUE self, VALUE v_collision);
    static VALUE rbf_destroy_collision(VALUE self, VALUE v_collision);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_WORLD_H */
