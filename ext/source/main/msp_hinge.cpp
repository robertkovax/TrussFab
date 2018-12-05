/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_hinge.h"
#include "msp_joint.h"
#include "msp_world.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::Hinge::DEFAULT_MIN(-30.0 * M_DEG_TO_RAD);
const treal MSP::Hinge::DEFAULT_MAX(30.0 * M_DEG_TO_RAD);
const treal MSP::Hinge::DEFAULT_FRICTION(0.0);
const bool MSP::Hinge::DEFAULT_LIMITS_ENABLED(false);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

MSP::Hinge::ChildData* MSP::Hinge::c_get_child_data(Joint::Data* joint_data) {
    return reinterpret_cast<ChildData*>(joint_data->m_cdata);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Hinge::on_update(Joint::Data* joint_data, const NewtonJoint* joint, treal dt, int thread_index) {
    ChildData* cj_data = c_get_child_data(joint_data);

    treal sin_angle, cos_angle, omega, stop_accel;
    Geom::Vector3d omega0(0.0);
    Geom::Vector3d omega1(0.0);
    Geom::Transformation matrix0, matrix1;

    treal dt_inv = (treal)(1.0) / dt;

    MSP::Joint::c_calculate_global_matrix(joint_data, matrix0, matrix1);
    Joint::c_calculate_angle(matrix1.m_xaxis, matrix0.m_xaxis, matrix0.m_zaxis, sin_angle, cos_angle);
    cj_data->m_ai.update(cos_angle, sin_angle);

    // Obtain angular velocity
    NewtonBodyGetOmega(joint_data->m_child, &omega0[0]);
    if (joint_data->m_parent)
        NewtonBodyGetOmega(joint_data->m_parent, &omega1[0]);

    // Compute angular velocity
    cj_data->m_cur_omega = (omega0 - omega1).dot(matrix0.m_zaxis);

    // Restrict translation on axes
    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_xaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_yaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_zaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    // Restrict rotation on axes orthogonal to axis of rotation
    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix1.m_zaxis, matrix0.m_zaxis, matrix0.m_xaxis), &matrix0.m_xaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix1.m_zaxis, matrix0.m_zaxis, matrix0.m_yaxis), &matrix0.m_yaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    // Compute tension
    joint_data->m_tension1 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 0)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 1)) +
        matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 2));

    joint_data->m_tension2 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 3)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 4));

    // Apply limits and friction
    if (cj_data->m_limits_enabled && cj_data->m_ai.m_angle < cj_data->m_min) {
        NewtonUserJointAddAngularRow(joint, 0.0, &matrix0.m_zaxis[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);
        NewtonUserJointSetRowMinimumFriction(joint, -cj_data->m_friction);

        omega = 0.5f * (cj_data->m_min - cj_data->m_ai.m_angle) * dt_inv;
        stop_accel = NewtonUserJointCalculateRowZeroAccelaration(joint) + omega * dt_inv;
        NewtonUserJointSetRowAcceleration(joint, stop_accel);
    }
    else if (cj_data->m_limits_enabled && cj_data->m_ai.m_angle > cj_data->m_max) {
        NewtonUserJointAddAngularRow(joint, 0.0, &matrix0.m_zaxis[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);
        NewtonUserJointSetRowMinimumFriction(joint, cj_data->m_friction);

        omega = 0.5f * (cj_data->m_max - cj_data->m_ai.m_angle) * dt_inv;
        stop_accel = NewtonUserJointCalculateRowZeroAccelaration(joint) + omega * dt_inv;
        NewtonUserJointSetRowAcceleration(joint, stop_accel);
    }
    else if (cj_data->m_friction > M_EPSILON){
        NewtonUserJointAddAngularRow(joint, 0, &matrix0.m_zaxis[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);
        NewtonUserJointSetRowAcceleration(joint, -cj_data->m_cur_omega * dt_inv);
        NewtonUserJointSetRowMinimumFriction(joint, -cj_data->m_friction);
        NewtonUserJointSetRowMaximumFriction(joint, cj_data->m_friction);
        joint_data->m_tension2 += matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 5));
    }
}

void MSP::Hinge::on_destroy(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    delete cj_data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Hinge::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group, VALUE v_initial_angle) {
    treal init_angle = RU::value_to_treal(v_initial_angle);
    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, v_matrix, v_group, 6, on_update, on_destroy, nullptr, nullptr);

    ChildData* cj_data = new ChildData;
    cj_data->m_ai.m_angle = init_angle;
    joint_data->m_cdata = cj_data;

    Joint::c_create_end(self, joint_data);
    return self;
}

VALUE MSP::Hinge::rbf_get_min(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_min);
}

VALUE MSP::Hinge::rbf_set_min(VALUE self, VALUE v_min) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_min = RU::value_to_treal(v_min);
    return Qnil;
}

VALUE MSP::Hinge::rbf_get_max(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_max);
}

VALUE MSP::Hinge::rbf_set_max(VALUE self, VALUE v_max) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_max = RU::value_to_treal(v_max);
    return Qnil;
}

VALUE MSP::Hinge::rbf_get_friction(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_friction);
}

VALUE MSP::Hinge::rbf_set_friction(VALUE self, VALUE v_friction) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_friction = Geom::max_treal(RU::value_to_treal(v_friction), 0.0);
    return Qnil;
}

VALUE MSP::Hinge::rbf_get_cur_angle(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_ai.m_angle);
}

VALUE MSP::Hinge::rbf_get_cur_omega(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_omega);
}

VALUE MSP::Hinge::rbf_limits_enabled(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_limits_enabled);
}

VALUE MSP::Hinge::rbf_enable_limits(VALUE self, VALUE v_state) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_limits_enabled = RU::value_to_bool(v_state);
    return Qnil;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Hinge::init_ruby(VALUE mMSP) {
    VALUE cHinge = rb_define_class_under(mMSP, "Hinge", rba_cJoint);

    rb_define_alloc_func(cHinge, Joint::c_class_allocate);

    rb_define_const(cHinge, "DEFAULT_MIN", RU::to_value(DEFAULT_MIN));
    rb_define_const(cHinge, "DEFAULT_MAX", RU::to_value(DEFAULT_MAX));
    rb_define_const(cHinge, "DEFAULT_FRICTION", RU::to_value(DEFAULT_FRICTION));
    rb_define_const(cHinge, "DEFAULT_LIMITS_ENABLED", RU::to_value(DEFAULT_LIMITS_ENABLED));

    rb_define_method(cHinge, "initialize", VALUEFUNC(rbf_initialize), 6);
    rb_define_method(cHinge, "min", VALUEFUNC(rbf_get_min), 0);
    rb_define_method(cHinge, "min=", VALUEFUNC(rbf_set_min), 1);
    rb_define_method(cHinge, "max", VALUEFUNC(rbf_get_max), 0);
    rb_define_method(cHinge, "max=", VALUEFUNC(rbf_set_max), 1);
    rb_define_method(cHinge, "friction", VALUEFUNC(rbf_get_friction), 0);
    rb_define_method(cHinge, "friction=", VALUEFUNC(rbf_set_friction), 1);
    rb_define_method(cHinge, "cur_angle", VALUEFUNC(rbf_get_cur_angle), 0);
    rb_define_method(cHinge, "cur_omega", VALUEFUNC(rbf_get_cur_omega), 0);
    rb_define_method(cHinge, "limits_enabled?", VALUEFUNC(rbf_limits_enabled), 0);
    rb_define_method(cHinge, "limits_enabled=", VALUEFUNC(rbf_enable_limits), 1);
}
