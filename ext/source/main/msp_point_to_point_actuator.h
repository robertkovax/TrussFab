/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_POINT_TO_POINT_ACTUATOR_H
#define MSP_POINT_TO_POINT_ACTUATOR_H

#include "msp.h"
#include "msp_joint.h"

class MSP::PointToPointActuator {
public:
    // Constants
    static const treal DEFAULT_RATE;
    static const treal DEFAULT_POWER;
    static const treal DEFAULT_REDUCTION_RATIO;
    static const treal DEFAULT_CONTROLLER;

    // Structures
    struct ChildData {
        Geom::Vector3d m_point1;
        Geom::Vector3d m_point2;
        Geom::Vector3d m_cur_normal;
        treal m_start_distance;
        treal m_cur_distance;
        treal m_cur_velocity;
        treal m_rate;
        treal m_power;
        treal m_reduction_ratio;
        treal m_controller;
        treal m_mrt;
        treal m_mrt_inv;
        void(*m_limit_power_proc)(Joint::Data* joint_data);

        ChildData() :
            m_start_distance(0.0),
            m_cur_distance(0.0),
            m_cur_velocity(0.0),
            m_rate(DEFAULT_RATE * M_METER_TO_INCH),
            m_power(DEFAULT_POWER * M_METER_TO_INCH),
            m_reduction_ratio(DEFAULT_REDUCTION_RATIO),
            m_controller(DEFAULT_CONTROLLER * M_METER_TO_INCH)
        {
            m_limit_power_proc = nullptr;
        }
    };

    // Helper Functions
    static ChildData* c_get_child_data(Joint::Data* joint_data);
    static void c_update_mrt(ChildData* cj_data);
    static void c_update_power_limits(Joint::Data* joint_data);

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, treal dt, int thread_index);
    static void on_destroy(Joint::Data* joint_data);
    static void on_limit_power(Joint::Data* joint_data);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group);
    static VALUE rbf_get_point1(VALUE self);
    static VALUE rbf_set_point1(VALUE self, VALUE v_point);
    static VALUE rbf_get_point2(VALUE self);
    static VALUE rbf_set_point2(VALUE self, VALUE v_point);
    static VALUE rbf_get_start_distance(VALUE self);
    static VALUE rbf_set_start_distance(VALUE self, VALUE v_distance);
    static VALUE rbf_get_cur_distance(VALUE self);
    static VALUE rbf_get_cur_velocity(VALUE self);
    static VALUE rbf_get_cur_normal(VALUE self);
    static VALUE rbf_get_rate(VALUE self);
    static VALUE rbf_set_rate(VALUE self, VALUE v_rate);
    static VALUE rbf_get_power(VALUE self);
    static VALUE rbf_set_power(VALUE self, VALUE v_power);
    static VALUE rbf_get_reduction_ratio(VALUE self);
    static VALUE rbf_set_reduction_ratio(VALUE self, VALUE v_reduction_ratio);
    static VALUE rbf_get_controller(VALUE self);
    static VALUE rbf_set_controller(VALUE self, VALUE v_controller);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_POINT_TO_POINT_ACTUATOR_H */
