/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_BODY_H
#define MSP_BODY_H

#include "msp.h"

class MSP::Body {
public:
    // Constants
    static const treal MIN_MASS;
    static const treal MAX_MASS;
    static const treal MIN_VOLUME;
    static const treal MAX_VOLUME;
    static const treal MIN_DENSITY;
    static const treal MAX_DENSITY;
    static const treal DEFAULT_DENSITY;
    static const treal DEFAULT_ELASTICITY;
    static const treal DEFAULT_SOFTNESS;
    static const treal DEFAULT_STATIC_FRICTION_COEF;
    static const treal DEFAULT_KINETIC_FRICTION_COEF;
    static const treal DEFAULT_MAGNET_STRENGTH;
    static const Geom::Vector3d DEFAULT_DIPOLE_DIR;
    static const bool DEFAULT_FRICTION_ENABLED;
    static const bool DEFAULT_AUTO_SLEEP_ENABLED;
    static const bool DEFAULT_STATIC;
    static const bool DEFAULT_COLLIDABLE;
    static const bool DEFAULT_MAGNETIC;

    // Structures
    struct Triplet {
        Geom::Vector3d m_normal;
        Geom::Vector3d m_centre;
        treal m_area;
        int m_i0;
        int m_i1;
        int m_i2;
    };

    struct Data {
        NewtonBody* m_body;
        VALUE v_group;
        VALUE v_self;
        Geom::Vector3d m_applied_force;
        Geom::Vector3d m_applied_torque;
        Geom::Vector3d m_def_tra_scale;
        Geom::Vector3d m_def_tra_scale_inv;
        Geom::Vector3d m_act_tra_scale;
        Geom::Vector3d m_act_tra_scale_inv;
        Geom::Vector3d m_def_col_scale;
        Geom::Vector3d m_def_col_scale_inv;
        Geom::Vector3d m_def_col_offset;
        Geom::Vector3d m_dipole_dir;
        Geom::Vector3d m_drag_profile;
        treal m_density;
        treal m_volume;
        treal m_mass;
        treal m_mass_inv;
        treal m_elasticity;
        treal m_softness;
        treal m_static_friction;
        treal m_kinetic_friction;
        treal m_magnet_strength;
        bool m_friction_enabled;
        bool m_auto_sleep_enabled;
        bool m_static;
        bool m_can_be_dynamic;
        bool m_collidable;
        bool m_magnetic;
        bool m_matrix_changed;
        unsigned int m_num_points;
        unsigned int m_num_triplets;

        Data() :
            m_applied_force(0.0),
            m_applied_torque(0.0),
            m_drag_profile(0.0),
            m_dipole_dir(DEFAULT_DIPOLE_DIR),
            m_density(DEFAULT_DENSITY),
            m_elasticity(DEFAULT_ELASTICITY),
            m_softness(DEFAULT_SOFTNESS),
            m_static_friction(DEFAULT_STATIC_FRICTION_COEF),
            m_kinetic_friction(DEFAULT_KINETIC_FRICTION_COEF),
            m_magnet_strength(DEFAULT_MAGNET_STRENGTH),
            m_friction_enabled(DEFAULT_FRICTION_ENABLED),
            m_auto_sleep_enabled(DEFAULT_AUTO_SLEEP_ENABLED),
            m_static(DEFAULT_STATIC),
            m_collidable(DEFAULT_COLLIDABLE),
            m_magnetic(DEFAULT_MAGNETIC),
            m_matrix_changed(false)
        {
            m_body = nullptr;
            v_group = Qnil;
            v_self = Qnil;
        }
    };

    // Helper Functions
    static VALUE c_class_allocate(VALUE klass);
    static void c_class_mark(void* data);
    static void c_class_deallocate(void* data);
    static Data* c_to_data(VALUE self);
    static Data* c_to_data(const NewtonBody* body);

    // Callback Functions
    static void destructor_callback(const NewtonBody* const body);
    static void transform_callback(const NewtonBody* const body, const treal* const matrix, int thread_index);
    static void force_and_torque_callback(const NewtonBody* const body, treal timestep, int thread_index);
    static void collision_iterator1(void* const user_data, int vertex_vount, const treal* const face_array, int face_Id);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_collision, VALUE v_matrix, VALUE v_group);
    static VALUE rbf_initialize_copy(VALUE self, VALUE orig_self);

    static VALUE rbf_is_valid(VALUE self);
    static VALUE rbf_destroy(VALUE self);

    static VALUE rbf_get_group(VALUE self);
    static VALUE rbf_get_world(VALUE self);

    static VALUE rbf_get_mass(VALUE self);
    static VALUE rbf_set_mass(VALUE self, VALUE v_mass);
    static VALUE rbf_get_density(VALUE self);
    static VALUE rbf_set_density(VALUE self, VALUE v_density);
    static VALUE rbf_get_volume(VALUE self);
    static VALUE rbf_set_volume(VALUE self, VALUE v_volume);

    static VALUE rbf_get_centre_of_mass(VALUE self);
    static VALUE rbf_set_centre_of_mass(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_get_mass_matrix(VALUE self);
    static VALUE rbf_set_mass_matrix(VALUE self, VALUE v_ixx, VALUE v_iyy, VALUE v_izz, VALUE v_mass);

    static VALUE rbf_get_velocity(VALUE self);
    static VALUE rbf_set_velocity(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_get_point_velocity(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_get_omega(VALUE self);
    static VALUE rbf_set_omega(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_get_transformation(VALUE self);
    static VALUE rbf_set_transformation(VALUE self, VALUE v_matrix);
    static VALUE rbf_get_position(VALUE self, VALUE v_mode);
    static VALUE rbf_set_position(VALUE self, VALUE v_mode, VALUE v_position);
    static VALUE rbf_get_rotation(VALUE self);
    static VALUE rbf_get_euler_angles(VALUE self);
    static VALUE rbf_set_euler_angles(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_get_scale(VALUE self);
    static VALUE rbf_set_scale(int argc, VALUE* argv, VALUE self);

    static VALUE rbf_get_aabb(VALUE self);

    static VALUE rbf_is_static(VALUE self);
    static VALUE rbf_set_static(VALUE self, VALUE v_state);
    static VALUE rbf_is_collidable(VALUE self);
    static VALUE rbf_set_collidable(VALUE self, VALUE v_state);
    static VALUE rbf_is_frozen(VALUE self);
    static VALUE rbf_set_frozen(VALUE self, VALUE v_state);
    static VALUE rbf_is_asleep(VALUE self);
    static VALUE rbf_activate(VALUE self);
    static VALUE rbf_is_magnetic(VALUE self);
    static VALUE rbf_set_magnetic(VALUE self, VALUE v_state);

    static VALUE rbf_get_auto_sleep_state(VALUE self);
    static VALUE rbf_set_auto_sleep_state(VALUE self, VALUE v_state);
    static VALUE rbf_get_continuous_collision_state(VALUE self);
    static VALUE rbf_set_continuous_collision_state(VALUE self, VALUE v_state);
    static VALUE rbf_get_friction_state(VALUE self);
    static VALUE rbf_set_friction_state(VALUE self, VALUE v_state);

    static VALUE rbf_get_elasticity(VALUE self);
    static VALUE rbf_set_elasticity(VALUE self, VALUE v_coef);
    static VALUE rbf_get_softness(VALUE self);
    static VALUE rbf_set_softness(VALUE self, VALUE v_coef);
    static VALUE rbf_get_static_friction(VALUE self);
    static VALUE rbf_set_static_friction(VALUE self, VALUE v_coef);
    static VALUE rbf_get_kinetic_friction(VALUE self);
    static VALUE rbf_set_kinetic_friction(VALUE self, VALUE v_coef);

    static VALUE rbf_get_dipole_dir(VALUE self);
    static VALUE rbf_set_dipole_dir(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_get_magnet_strength(VALUE self);
    static VALUE rbf_set_magnet_strength(VALUE self, VALUE v_strength);

    static VALUE rbf_apply_impulse(VALUE self, VALUE v_center, VALUE v_delta_vel);
    static VALUE rbf_apply_force_at_point(VALUE self, VALUE v_point, VALUE v_force);
    static VALUE rbf_apply_force(int argc, VALUE* argv, VALUE self);
    static VALUE rbf_apply_torque(int argc, VALUE* argv, VALUE self);

    static VALUE rbf_get_acceleration(VALUE self);
    static VALUE rbf_get_alpha(VALUE self);
    static VALUE rbf_get_tension(VALUE self);

    static VALUE rbf_get_contained_joints(VALUE self);
    static VALUE rbf_get_connected_joints(VALUE self);
    static VALUE rbf_get_connected_bodies(VALUE self);

    static VALUE rbf_apply_pick_and_drag(VALUE self, VALUE v_pick_pt, VALUE v_dest_pt, VALUE v_stiffness, VALUE v_damp);
    static VALUE rbf_apply_buoyancy(VALUE self, VALUE v_plane_origin, VALUE v_plane_normal, VALUE v_density, VALUE v_linear_viscosity, VALUE v_angular_viscosity, VALUE v_linear_current, VALUE v_angular_current);

    static VALUE rbf_get_contacts(VALUE self, VALUE v_inc_non_collidable);
    static VALUE rbf_get_touching_bodies(VALUE self, VALUE v_inc_non_collidable);
    static VALUE rbf_is_touching_with(VALUE self, VALUE v_other_body);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_BODY_H */
