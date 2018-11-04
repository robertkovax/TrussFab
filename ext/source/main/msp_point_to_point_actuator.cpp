/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_point_to_point_actuator.h"
#include "msp_joint.h"
#include "msp_world.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::PointToPointActuator::DEFAULT_RATE(40.0);
const treal MSP::PointToPointActuator::DEFAULT_POWER(0.0);
const treal MSP::PointToPointActuator::DEFAULT_REDUCTION_RATIO(0.1);
const treal MSP::PointToPointActuator::DEFAULT_CONTROLLER(0.0);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

MSP::PointToPointActuator::ChildData* MSP::PointToPointActuator::c_get_child_data(Joint::Data* joint_data) {
    return reinterpret_cast<ChildData*>(joint_data->m_cdata);
}

void MSP::PointToPointActuator::c_update_mrt(ChildData* cj_data) {
    cj_data->m_mrt = cj_data->m_rate * cj_data->m_reduction_ratio;
    if (cj_data->m_mrt > M_EPSILON)
        cj_data->m_mrt_inv = (treal)(1.0) / cj_data->m_mrt;
    else
        cj_data->m_mrt_inv = 0.0;
}

void MSP::PointToPointActuator::c_update_power_limits(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    if (cj_data->m_power > M_EPSILON)
        cj_data->m_limit_power_proc = on_limit_power;
    else
        cj_data->m_limit_power_proc = Joint::do_nothing;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::PointToPointActuator::on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index) {
    ChildData* cj_data = c_get_child_data(joint_data);
    World::Data* world_data = World::c_to_data(joint_data->m_world);

    Geom::Transformation matrix;
    Geom::Vector3d pt1, pt2;
    Geom::Vector3d v1(0.0);
    Geom::Vector3d v2(0.0);
    treal dx, dv, lv;

    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        pt1 = matrix.transform_vector2(cj_data->m_point1);
        NewtonBodyGetPointVelocity(joint_data->m_parent, &pt1[0], &v1[0]);
    }
    else
        pt1 = cj_data->m_point1;

    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    pt2 = matrix.transform_vector2(cj_data->m_point2);
    NewtonBodyGetPointVelocity(joint_data->m_child, &pt2[0], &v2[0]);

    cj_data->m_cur_normal = pt2 - pt1;
    cj_data->m_cur_distance = cj_data->m_cur_normal.get_length();

    if (cj_data->m_cur_distance > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_distance);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    cj_data->m_cur_velocity = (v2 - v1).dot(cj_data->m_cur_normal);

    dx = cj_data->m_start_distance + cj_data->m_controller - cj_data->m_cur_distance;
    dv = dx * world_data->m_timestep_inv;

    if (cj_data->m_mrt > M_EPSILON && fabs(dx) < cj_data->m_mrt) {
        lv = cj_data->m_rate * dx * cj_data->m_mrt_inv;
        Geom::clamp_treal2(dv, -lv, lv);
    }
    else
        Geom::clamp_treal2(dv, -cj_data->m_rate, cj_data->m_rate);

    NewtonUserJointAddLinearRow(joint, &pt2[0], &pt2[0], &cj_data->m_cur_normal[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    NewtonUserJointSetRowAcceleration(joint, (dv - cj_data->m_cur_velocity) * world_data->m_timestep_inv);
    cj_data->m_limit_power_proc(joint_data);

    // Update tensions
    joint_data->m_tension1 = cj_data->m_cur_normal.scale(NewtonUserJointGetRowForce(joint, 0));
}

void MSP::PointToPointActuator::on_destroy(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    delete cj_data;
}

void MSP::PointToPointActuator::on_limit_power(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    NewtonUserJointSetRowMinimumFriction(joint_data->m_joint, -cj_data->m_power);
    NewtonUserJointSetRowMaximumFriction(joint_data->m_joint, cj_data->m_power);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::PointToPointActuator::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group) {
    Geom::Vector3d pt1, pt2;
    Geom::Transformation matrix, matrix_inv;

    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, Qnil, v_group, 1, on_update, on_destroy, c_update_power_limits, nullptr);

    RU::value_to_vector(v_pt1, pt1);
    RU::value_to_vector(v_pt2, pt2);

    ChildData* cj_data = new ChildData;

    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        matrix_inv = matrix.inverse();
        cj_data->m_point1 = matrix_inv.transform_vector2(pt1);
    }
    else
        cj_data->m_point1 = pt1;

    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    matrix_inv = matrix.inverse();
    cj_data->m_point2 = matrix_inv.transform_vector2(pt2);

    cj_data->m_cur_normal = pt2 - pt1;
    cj_data->m_start_distance = cj_data->m_cur_normal.get_length();
    cj_data->m_cur_distance = cj_data->m_start_distance;

    if (cj_data->m_cur_distance > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_distance);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    joint_data->m_cdata = cj_data;

    c_update_mrt(cj_data);

    Joint::c_create_end(self, joint_data);

    return self;
}

VALUE MSP::PointToPointActuator::rbf_get_point1(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Transformation matrix;
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        return RU::point_to_value(matrix.transform_vector2(cj_data->m_point1));
    }
    else {
        return RU::point_to_value(cj_data->m_point1);
    }
}

VALUE MSP::PointToPointActuator::rbf_set_point1(VALUE self, VALUE v_point) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Vector3d point;
    Geom::Transformation matrix, matrix_inv;
    RU::value_to_vector(v_point, point);
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        matrix_inv = matrix.inverse();
        cj_data->m_point1 = matrix_inv.transform_vector2(point);
    }
    else {
        cj_data->m_point1 = point;
    }
    return Qnil;
}

VALUE MSP::PointToPointActuator::rbf_get_point2(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    return RU::point_to_value(matrix.transform_vector2(cj_data->m_point2));
}

VALUE MSP::PointToPointActuator::rbf_set_point2(VALUE self, VALUE v_point) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Vector3d point;
    Geom::Transformation matrix, matrix_inv;
    RU::value_to_vector(v_point, point);
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    matrix_inv = matrix.inverse();
    cj_data->m_point2 = matrix_inv.transform_vector2(point);
    return Qnil;
}

VALUE MSP::PointToPointActuator::rbf_get_start_distance(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_start_distance * M_INCH_TO_METER);
}

VALUE MSP::PointToPointActuator::rbf_set_start_distance(VALUE self, VALUE v_distance) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_start_distance = Geom::max_treal(RU::value_to_treal(v_distance), 0.0) * M_METER_TO_INCH;
    return Qnil;
}

VALUE MSP::PointToPointActuator::rbf_get_cur_distance(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_distance * M_INCH_TO_METER);
}

VALUE MSP::PointToPointActuator::rbf_get_cur_velocity(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_velocity * M_INCH_TO_METER);
}

VALUE MSP::PointToPointActuator::rbf_get_cur_normal(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::vector_to_value(cj_data->m_cur_normal);
}

VALUE MSP::PointToPointActuator::rbf_get_rate(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_rate * M_INCH_TO_METER);
}

VALUE MSP::PointToPointActuator::rbf_set_rate(VALUE self, VALUE v_rate) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_rate = Geom::max_treal(RU::value_to_treal(v_rate), 0.0) * M_METER_TO_INCH;
    c_update_mrt(cj_data);
    return Qnil;
}

VALUE MSP::PointToPointActuator::rbf_get_reduction_ratio(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_reduction_ratio);
}

VALUE MSP::PointToPointActuator::rbf_set_reduction_ratio(VALUE self, VALUE v_reduction_ratio) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_reduction_ratio = Geom::clamp_treal(RU::value_to_treal(v_reduction_ratio), 0.0, 1.0);
    c_update_mrt(cj_data);
    return Qnil;
}

VALUE MSP::PointToPointActuator::rbf_get_power(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_power * M_INCH_TO_METER);
}

VALUE MSP::PointToPointActuator::rbf_set_power(VALUE self, VALUE v_power) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_power = Geom::max_treal(RU::value_to_treal(v_power), 0.0) * M_METER_TO_INCH;
    c_update_power_limits(joint_data);
    return Qnil;
}

VALUE MSP::PointToPointActuator::rbf_get_controller(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_controller * M_INCH_TO_METER);
}

VALUE MSP::PointToPointActuator::rbf_set_controller(VALUE self, VALUE v_controller) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    treal last_controller = cj_data->m_controller;
    cj_data->m_controller = RU::value_to_treal(v_controller) * M_METER_TO_INCH;
    if (fabs(cj_data->m_controller - last_controller) > M_EPSILON) {
        NewtonBodySetSleepState(joint_data->m_child, 0);
    }
    return Qnil;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::PointToPointActuator::init_ruby(VALUE mMSP) {
    VALUE cPointToPointActuator = rb_define_class_under(mMSP, "PointToPointActuator", rba_cJoint);

    rb_define_alloc_func(cPointToPointActuator, Joint::c_class_allocate);

    rb_define_const(cPointToPointActuator, "DEFAULT_RATE", RU::to_value(DEFAULT_RATE));
    rb_define_const(cPointToPointActuator, "DEFAULT_POWER", RU::to_value(DEFAULT_POWER));
    rb_define_const(cPointToPointActuator, "DEFAULT_REDUCTION_RATIO", RU::to_value(DEFAULT_REDUCTION_RATIO));
    rb_define_const(cPointToPointActuator, "DEFAULT_CONTROLLER", RU::to_value(DEFAULT_CONTROLLER));

    rb_define_method(cPointToPointActuator, "initialize", VALUEFUNC(rbf_initialize), 6);
    rb_define_method(cPointToPointActuator, "get_point1", VALUEFUNC(rbf_get_point1), 0);
    rb_define_method(cPointToPointActuator, "set_point1", VALUEFUNC(rbf_set_point1), 1);
    rb_define_method(cPointToPointActuator, "get_point2", VALUEFUNC(rbf_get_point2), 0);
    rb_define_method(cPointToPointActuator, "set_point2", VALUEFUNC(rbf_set_point2), 1);
    rb_define_method(cPointToPointActuator, "start_distance", VALUEFUNC(rbf_get_start_distance), 0);
    rb_define_method(cPointToPointActuator, "start_distance=", VALUEFUNC(rbf_set_start_distance), 1);
    rb_define_method(cPointToPointActuator, "cur_distance", VALUEFUNC(rbf_get_cur_distance), 0);
    rb_define_method(cPointToPointActuator, "cur_velocity", VALUEFUNC(rbf_get_cur_velocity), 0);
    rb_define_method(cPointToPointActuator, "cur_normal", VALUEFUNC(rbf_get_cur_normal), 0);
    rb_define_method(cPointToPointActuator, "rate", VALUEFUNC(rbf_get_rate), 0);
    rb_define_method(cPointToPointActuator, "rate=", VALUEFUNC(rbf_set_rate), 1);
    rb_define_method(cPointToPointActuator, "reduction_ratio", VALUEFUNC(rbf_get_reduction_ratio), 0);
    rb_define_method(cPointToPointActuator, "reduction_ratio=", VALUEFUNC(rbf_set_reduction_ratio), 1);
    rb_define_method(cPointToPointActuator, "power", VALUEFUNC(rbf_get_power), 0);
    rb_define_method(cPointToPointActuator, "power=", VALUEFUNC(rbf_set_power), 1);
    rb_define_method(cPointToPointActuator, "controller", VALUEFUNC(rbf_get_controller), 0);
    rb_define_method(cPointToPointActuator, "controller=", VALUEFUNC(rbf_set_controller), 1);
}
