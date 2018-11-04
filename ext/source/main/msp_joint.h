/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_JOINT_H
#define MSP_JOINT_H

#include "msp.h"

class MSP::Joint {
public:
    // Constants
    static const treal DEFAULT_STIFFNESS;
    static const treal DEFAULT_STIFFNESS_RANGE;
    static const treal DEFAULT_BREAKING_FORCE;
    static const treal CUSTOM_LARGE_VALUE;
    static const int DEFAULT_SOLVER_MODEL;
    static const bool DEFAULT_BODIES_COLLIDABLE;

    // Structures
    struct Data {
        const NewtonJoint* m_joint;
        const NewtonWorld* m_world;
        const NewtonBody* m_parent;
        const NewtonBody* m_child;
        void* m_cdata;

        VALUE v_group;
        VALUE v_self;

        void(*m_on_update)(Data* joint_data, const NewtonJoint* joint, int thread_index);
        void(*m_on_destroy)(Data* joint_data);
        void(*m_on_breaking_force_changed)(Data* joint_data);
        void(*m_on_adjust_pin_matrix)(Data* joint_data, Geom::Transformation& pin_matrix);
        void(*m_limit_min_row_proc)(Data* joint_data);
        void(*m_limit_max_row_proc)(Data* joint_data);

        Geom::Transformation m_pin_matrix;
        Geom::Transformation m_local_matrix0;
        Geom::Transformation m_local_matrix1;
        Geom::Transformation m_local_matrix2;

        Geom::Vector3d m_tension1;
        Geom::Vector3d m_tension2;

        treal m_stiffness;
        treal m_sf;
        treal m_breaking_force;
        treal m_breaking_force_sq;

        int m_solver_model;
        int m_dof;
        bool m_bodies_collidable;

        Data() :
            m_tension1(0.0),
            m_tension2(0.0),
            m_stiffness(DEFAULT_STIFFNESS),
            m_breaking_force(DEFAULT_BREAKING_FORCE),
            m_solver_model(DEFAULT_SOLVER_MODEL),
            m_bodies_collidable(DEFAULT_BODIES_COLLIDABLE)
        {
            m_joint = nullptr;
            m_world = nullptr;
            m_parent = nullptr;
            m_child = nullptr;
            m_cdata = nullptr;

            v_group = Qnil;
            v_self = Qnil;

            m_on_update = nullptr;
            m_on_destroy = nullptr;
            m_on_breaking_force_changed = nullptr;
            m_on_adjust_pin_matrix = nullptr;
            m_limit_min_row_proc = nullptr;
            m_limit_max_row_proc = nullptr;
        }
    };

    // Typedefines
    typedef void(*OnUpdate)(Data* joint_data, const NewtonJoint* joint, int thread_index);
    typedef void(*OnDestroy)(Data* joint_data);
    typedef void(*OnBreakingForceChanged)(Data* joint_data);
    typedef void(*OnAdjustPinMatrix)(Data* joint_data, Geom::Transformation& pin_matrix);

    // Helper Functions
    static VALUE c_class_allocate(VALUE klass);
    static void c_class_mark(void* data);
    static void c_class_deallocate(void* data);
    static Data* c_to_data(VALUE v_joint);
    static Data* c_to_data(const NewtonJoint* joint);
    static Data* c_to_data_simple_cast(VALUE v_joint);
    static Data* c_create_begin(
        VALUE self,
        VALUE v_world,
        VALUE v_parent,
        VALUE v_child,
        VALUE v_matrix,
        VALUE v_group,
        int dof,
        OnUpdate on_update,
        OnDestroy on_destroy,
        OnBreakingForceChanged on_breaking_force_changed,
        OnAdjustPinMatrix on_adjust_pin_matrix);
    static void c_create_end(VALUE self, Data* joint_data);
    static void c_update_breaking_info(Data* joint_data);
    static void c_update_stiffness_factor(Data* joint_data);

    static void c_update_local_matrix(Data* joint_data);
    static void c_calculate_global_matrix(Data* joint_data, Geom::Transformation& matrix0, Geom::Transformation& matrix1);
    static void c_calculate_global_matrix2(Data* joint_data, Geom::Transformation& matrix0, Geom::Transformation& matrix1, Geom::Transformation& matrix2);
    static void c_calculate_global_parent_matrix(Data* joint_data, Geom::Transformation& parent_matrix);
    static void c_calculate_angle(const Geom::Vector3d& dir, const Geom::Vector3d& cosDir, const Geom::Vector3d& sinDir, treal& sinAngle, treal& cosAngle);
    static treal c_calculate_angle2(const Geom::Vector3d& dir, const Geom::Vector3d& cosDir, const Geom::Vector3d& sinDir, treal& sinAngle, treal& cosAngle);
    static treal c_calculate_angle2(const Geom::Vector3d& dir, const Geom::Vector3d& cosDir, const Geom::Vector3d& sinDir);
    static void c_get_pin_matrix(Data* joint_data, Geom::Transformation& matrix_out);

    // Callback Functions
    static void submit_constraints(const NewtonJoint* joint, treal timestep, int thread_index);
    static void constraint_destructor(const NewtonJoint* joint);
    static void do_limit_min_row(Data* joint_data);
    static void do_limit_max_row(Data* joint_data);
    static void do_nothing(Data* joint_data);

    // Ruby Functions
    static VALUE rbf_is_valid(VALUE self);
    static VALUE rbf_destroy(VALUE self);

    static VALUE rbf_get_group(VALUE self);
    static VALUE rbf_get_world(VALUE self);
    static VALUE rbf_get_parent(VALUE self);
    static VALUE rbf_get_child(VALUE self);

    static VALUE rbf_get_breaking_force(VALUE self);
    static VALUE rbf_set_breaking_force(VALUE self, VALUE v_force_mag);
    static VALUE rbf_get_stiffness(VALUE self);
    static VALUE rbf_set_stiffness(VALUE self, VALUE v_stiffness);
    static VALUE rbf_get_solver_model(VALUE self);
    static VALUE rbf_set_solver_model(VALUE self, VALUE v_solver_model);
    static VALUE rbf_get_bodies_collidable_state(VALUE self);
    static VALUE rbf_set_bodies_collidable_state(VALUE self, VALUE v_stiffness);

    static VALUE rbf_get_linear_tension(VALUE self);
    static VALUE rbf_get_angular_tension(VALUE self);
    static VALUE rbf_get_pin_matrix(VALUE self);
    static VALUE rbf_set_pin_matrix(VALUE self, VALUE v_pin_matrix);
    static VALUE rbf_get_pin_matrix2(VALUE self, VALUE v_mode);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_JOINT_H */
