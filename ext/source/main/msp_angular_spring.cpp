/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_angular_spring.h"
#include "msp_joint.h"
#include "msp_world.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::AngularSpring::DEFAULT_MIN(-30.0 * M_DEG_TO_RAD);
const treal MSP::AngularSpring::DEFAULT_MAX(30.0 * M_DEG_TO_RAD);
const treal MSP::AngularSpring::DEFAULT_K(40.0);
const treal MSP::AngularSpring::DEFAULT_D(10.0);
const treal MSP::AngularSpring::DEFAULT_V(0.8);
const bool MSP::AngularSpring::DEFAULT_LIMITS_ENABLED(false);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

MSP::AngularSpring::ChildData* MSP::AngularSpring::c_get_child_data(Joint::Data* joint_data) {
    return reinterpret_cast<ChildData*>(joint_data->m_cdata);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::AngularSpring::on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index) {
    ChildData* cj_data = c_get_child_data(joint_data);
    World::Data* world_data = World::c_to_data(joint_data->m_world);

    treal sin_angle, cos_angle, omega, accel;
    Geom::Vector3d omega0(0.0);
    Geom::Vector3d omega1(0.0);
    Geom::Transformation matrix0, matrix1;

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
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);

    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_yaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);

    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_zaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);

    // Restrict rotation on axes orthogonal to axis of rotation
    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix1.m_zaxis, matrix0.m_zaxis, matrix0.m_xaxis), &matrix0.m_xaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);

    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix1.m_zaxis, matrix0.m_zaxis, matrix0.m_yaxis), &matrix0.m_yaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);

    // Apply limits and friction
    if (cj_data->m_limits_enabled && cj_data->m_ai.m_angle < cj_data->m_min) {
        NewtonUserJointAddAngularRow(joint, 0.0, &matrix0.m_zaxis[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);

        omega = 0.5f * (cj_data->m_min - cj_data->m_ai.m_angle) * world_data->m_timestep_inv;
        accel = NewtonUserJointCalculateRowZeroAccelaration(joint) + omega * world_data->m_timestep_inv;
        NewtonUserJointSetRowAcceleration(joint, accel);
    }
    else if (cj_data->m_limits_enabled && cj_data->m_ai.m_angle > cj_data->m_max) {
        NewtonUserJointAddAngularRow(joint, 0.0, &matrix0.m_zaxis[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);

        omega = 0.5f * (cj_data->m_max - cj_data->m_ai.m_angle) * world_data->m_timestep_inv;
        accel = NewtonUserJointCalculateRowZeroAccelaration(joint) + omega * world_data->m_timestep_inv;
        NewtonUserJointSetRowAcceleration(joint, accel);
    }
    else {
        NewtonUserJointAddAngularRow(joint, 0.0, &matrix0.m_zaxis[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_sf * cj_data->m_v);

        accel = cj_data->m_k * cj_data->m_ai.m_angle +
            cj_data->m_d * cj_data->m_cur_omega * world_data->m_timestep_inv;

        NewtonUserJointSetRowAcceleration(joint, -accel);
    }

    // Compute tension
    joint_data->m_tension1 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 0)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 1)) +
        matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 2));

    joint_data->m_tension2 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 3)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 4)) +
        matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 5));
}

void MSP::AngularSpring::on_destroy(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    delete cj_data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::AngularSpring::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group, VALUE v_initial_angle) {
    treal init_angle = RU::value_to_treal(v_initial_angle);
    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, v_matrix, v_group, 6, on_update, on_destroy, nullptr, nullptr);

    ChildData* cj_data = new ChildData;
    cj_data->m_ai.m_angle = init_angle;
    joint_data->m_cdata = cj_data;

    Joint::c_create_end(self, joint_data);
    return self;
}

VALUE MSP::AngularSpring::rbf_get_min(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_min);
}

VALUE MSP::AngularSpring::rbf_set_min(VALUE self, VALUE v_min) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_min = RU::value_to_treal(v_min);
    return Qnil;
}

VALUE MSP::AngularSpring::rbf_get_max(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_max);
}

VALUE MSP::AngularSpring::rbf_set_max(VALUE self, VALUE v_max) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_max = RU::value_to_treal(v_max);
    return Qnil;
}

VALUE MSP::AngularSpring::rbf_get_k(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_k);
}

VALUE MSP::AngularSpring::rbf_set_k(VALUE self, VALUE v_k) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_k = Geom::max_treal(RU::value_to_treal(v_k), 0.0);
    return Qnil;
}

VALUE MSP::AngularSpring::rbf_get_d(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_d);
}

VALUE MSP::AngularSpring::rbf_set_d(VALUE self, VALUE v_d) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_d = Geom::max_treal(RU::value_to_treal(v_d), 0.0);
    return Qnil;
}

VALUE MSP::AngularSpring::rbf_get_v(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_v);
}

VALUE MSP::AngularSpring::rbf_set_v(VALUE self, VALUE v_v) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_v = Geom::clamp_treal(RU::value_to_treal(v_v), 0.0, 1.0);
    return Qnil;
}

VALUE MSP::AngularSpring::rbf_get_cur_angle(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_ai.m_angle);
}

VALUE MSP::AngularSpring::rbf_get_cur_omega(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_omega);
}

VALUE MSP::AngularSpring::rbf_limits_enabled(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_limits_enabled);
}

VALUE MSP::AngularSpring::rbf_enable_limits(VALUE self, VALUE v_state) {
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

void MSP::AngularSpring::init_ruby(VALUE mMSP) {
    VALUE cAngularSpring = rb_define_class_under(mMSP, "AngularSpring", rba_cJoint);

    rb_define_alloc_func(cAngularSpring, Joint::c_class_allocate);

    rb_define_const(cAngularSpring, "DEFAULT_MIN", RU::to_value(DEFAULT_MIN));
    rb_define_const(cAngularSpring, "DEFAULT_MAX", RU::to_value(DEFAULT_MAX));
    rb_define_const(cAngularSpring, "DEFAULT_K", RU::to_value(DEFAULT_K));
    rb_define_const(cAngularSpring, "DEFAULT_D", RU::to_value(DEFAULT_D));
    rb_define_const(cAngularSpring, "DEFAULT_V", RU::to_value(DEFAULT_V));
    rb_define_const(cAngularSpring, "DEFAULT_LIMITS_ENABLED", RU::to_value(DEFAULT_LIMITS_ENABLED));

    rb_define_method(cAngularSpring, "initialize", VALUEFUNC(rbf_initialize), 6);
    rb_define_method(cAngularSpring, "min", VALUEFUNC(rbf_get_min), 0);
    rb_define_method(cAngularSpring, "min=", VALUEFUNC(rbf_set_min), 1);
    rb_define_method(cAngularSpring, "max", VALUEFUNC(rbf_get_max), 0);
    rb_define_method(cAngularSpring, "max=", VALUEFUNC(rbf_set_max), 1);
    rb_define_method(cAngularSpring, "k", VALUEFUNC(rbf_get_k), 0);
    rb_define_method(cAngularSpring, "k=", VALUEFUNC(rbf_set_k), 1);
    rb_define_method(cAngularSpring, "d", VALUEFUNC(rbf_get_d), 0);
    rb_define_method(cAngularSpring, "d=", VALUEFUNC(rbf_set_d), 1);
    rb_define_method(cAngularSpring, "v", VALUEFUNC(rbf_get_v), 0);
    rb_define_method(cAngularSpring, "v=", VALUEFUNC(rbf_set_v), 1);
    rb_define_method(cAngularSpring, "cur_angle", VALUEFUNC(rbf_get_cur_angle), 0);
    rb_define_method(cAngularSpring, "cur_omega", VALUEFUNC(rbf_get_cur_omega), 0);
    rb_define_method(cAngularSpring, "limits_enabled?", VALUEFUNC(rbf_limits_enabled), 0);
    rb_define_method(cAngularSpring, "limits_enabled=", VALUEFUNC(rbf_enable_limits), 1);
}
