/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_GENERIC_POINT_TO_POINT_H
#define MSP_GENERIC_POINT_TO_POINT_H

#include "msp.h"
#include "msp_joint.h"

class MSP::GenericPointToPoint {
public:
    // Constants
    static const treal DEFAULT_MIN_DISTANCE;
    static const treal DEFAULT_MAX_DISTANCE;
    static const treal DEFAULT_FORCE;
    static const bool DEFAULT_LIMITS_ENABLED;

    // Structures
    struct ChildData {
        DelayedForceAndTorque m_dftp;
        DelayedForceAndTorque m_dftc;
        Geom::Vector3d m_point1;
        Geom::Vector3d m_point2;
        Geom::Vector3d m_cur_normal;
        treal m_min_distance;
        treal m_max_distance;
        treal m_cur_distance;
        treal m_cur_velocity;
        treal m_force;
        treal m_factor;
        bool m_limits_enabled;

        ChildData() :
            m_min_distance(DEFAULT_MIN_DISTANCE * M_METER_TO_INCH),
            m_max_distance(DEFAULT_MAX_DISTANCE * M_METER_TO_INCH),
            m_cur_distance(0.0),
            m_cur_velocity(0.0),
            m_force(DEFAULT_FORCE * M_METER_TO_INCH),
            m_limits_enabled(DEFAULT_LIMITS_ENABLED)
        {
        }
    };

    // Helper Functions
    static ChildData* c_get_child_data(Joint::Data* joint_data);
    static void c_update_info(Joint::Data* joint_data);

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index);
    static void on_destroy(Joint::Data* joint_data);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group);
    static VALUE rbf_get_point1(VALUE self);
    static VALUE rbf_set_point1(VALUE self, VALUE v_point);
    static VALUE rbf_get_point2(VALUE self);
    static VALUE rbf_set_point2(VALUE self, VALUE v_point);
    static VALUE rbf_get_min_distance(VALUE self);
    static VALUE rbf_set_min_distance(VALUE self, VALUE v_length);
    static VALUE rbf_get_max_distance(VALUE self);
    static VALUE rbf_set_max_distance(VALUE self, VALUE v_length);
    static VALUE rbf_get_force(VALUE self);
    static VALUE rbf_set_force(VALUE self, VALUE v_force);
    static VALUE rbf_get_cur_distance(VALUE self);
    static VALUE rbf_get_cur_velocity(VALUE self);
    static VALUE rbf_get_cur_normal(VALUE self);
    static VALUE rbf_limits_enabled(VALUE self);
    static VALUE rbf_enable_limits(VALUE self,VALUE v_state);
    static VALUE rbf_update_info(VALUE self);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_GENERIC_POINT_TO_POINT_H */
