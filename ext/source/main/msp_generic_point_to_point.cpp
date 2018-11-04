/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_generic_point_to_point.h"
#include "msp_joint.h"
#include "msp_world.h"
#include "msp_body.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::GenericPointToPoint::DEFAULT_MIN_DISTANCE(0.5);
const treal MSP::GenericPointToPoint::DEFAULT_MAX_DISTANCE(1.0);
const treal MSP::GenericPointToPoint::DEFAULT_FORCE(0.0);
const bool MSP::GenericPointToPoint::DEFAULT_LIMITS_ENABLED(false);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

MSP::GenericPointToPoint::ChildData* MSP::GenericPointToPoint::c_get_child_data(Joint::Data* joint_data) {
    return reinterpret_cast<ChildData*>(joint_data->m_cdata);
}

void MSP::GenericPointToPoint::c_update_info(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    Body::Data* body_data1;
    Body::Data* body_data2;
    if (joint_data->m_parent)
        body_data1 = Body::c_to_data(joint_data->m_parent);
    else
        body_data1 = nullptr;
    body_data2 = Body::c_to_data(joint_data->m_child);

    if (body_data1 && !body_data1->m_static && !body_data2->m_static)
        cj_data->m_factor = (treal)(0.5);
    else
        cj_data->m_factor = (treal)(1.0);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::GenericPointToPoint::on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index) {
    ChildData* cj_data = c_get_child_data(joint_data);
    World::Data* world_data = World::c_to_data(joint_data->m_world);

    Geom::Transformation matrix;
    Geom::Vector3d v1(0.0);
    Geom::Vector3d v2(0.0);
    Geom::Vector3d pt1, pt2, ptx, centre1, centre2, force;
    treal dx, dv, sa;

    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        NewtonBodyGetCentreOfMass(joint_data->m_parent, &centre1[0]);
        pt1 = matrix.transform_vector2(cj_data->m_point1);
        centre1 = matrix.transform_vector2(centre1);
        NewtonBodyGetPointVelocity(joint_data->m_parent, &pt1[0], &v1[0]);
    }
    else {
        pt1 = cj_data->m_point1;
    }

    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    NewtonBodyGetCentreOfMass(joint_data->m_child, &centre2[0]);
    pt2 = matrix.transform_vector2(cj_data->m_point2);
    centre2 = matrix.transform_vector2(centre2);
    NewtonBodyGetPointVelocity(joint_data->m_child, &pt2[0], &v2[0]);

    cj_data->m_cur_normal = pt2 - pt1;
    cj_data->m_cur_distance = cj_data->m_cur_normal.get_length();

    if (cj_data->m_cur_distance > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_distance);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    cj_data->m_cur_velocity = (v2 - v1).dot(cj_data->m_cur_normal);

    force = cj_data->m_cur_normal.scale(cj_data->m_force * cj_data->m_factor);
    cj_data->m_dftp.m_force = force.reverse();
    cj_data->m_dftp.m_torque = force.cross((pt1 - centre1));
    cj_data->m_dftc.m_force = force;
    cj_data->m_dftc.m_torque = force.cross((centre2 - pt2));

    if (cj_data->m_cur_distance < cj_data->m_min_distance && cj_data->m_limits_enabled) {
        dx = cj_data->m_min_distance - cj_data->m_cur_distance;
        ptx = pt2 + cj_data->m_cur_normal.scale(dx);
        NewtonUserJointAddLinearRow(joint, &pt2[0], &ptx[0], &cj_data->m_cur_normal[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
        //joint_data->m_limit_min_row_proc(joint_data);
        dv = (treal)(0.5) * dx * world_data->m_timestep_inv;
        sa = NewtonUserJointCalculateRowZeroAccelaration(joint) + dv * world_data->m_timestep_inv;
        NewtonUserJointSetRowAcceleration(joint, sa);
        joint_data->m_tension1 = cj_data->m_cur_normal.scale(NewtonUserJointGetRowForce(joint, 0));
    }
    else if (cj_data->m_cur_distance > cj_data->m_max_distance && cj_data->m_limits_enabled) {
        dx = cj_data->m_max_distance - cj_data->m_cur_distance;
        ptx = pt2 + cj_data->m_cur_normal.scale(dx);
        NewtonUserJointAddLinearRow(joint, &pt2[0], &ptx[0], &cj_data->m_cur_normal[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
        //joint_data->m_limit_max_row_proc(joint_data);
        dv = (treal)(0.5) * dx * world_data->m_timestep_inv;
        sa = NewtonUserJointCalculateRowZeroAccelaration(joint) + dv * world_data->m_timestep_inv;
        NewtonUserJointSetRowAcceleration(joint, sa);
        joint_data->m_tension1 = cj_data->m_cur_normal.scale(NewtonUserJointGetRowForce(joint, 0));
    }
    else {
        joint_data->m_tension1 = cj_data->m_cur_normal.scale(cj_data->m_force);
    }
}

void MSP::GenericPointToPoint::on_destroy(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    World::Data* world_data = World::c_to_data(joint_data->m_world);
    if (world_data->m_dfts.find(&cj_data->m_dftp) != world_data->m_dfts.end())
        world_data->m_dfts.erase(&cj_data->m_dftp);
    if (world_data->m_dfts.find(&cj_data->m_dftc) != world_data->m_dfts.end())
        world_data->m_dfts.erase(&cj_data->m_dftc);
    delete cj_data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::GenericPointToPoint::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group) {
    Geom::Vector3d pt1, pt2;
    Geom::Transformation matrix, matrix_inv;

    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, Qnil, v_group, 1, on_update, on_destroy, nullptr, nullptr);

    RU::value_to_vector(v_pt1, pt1);
    RU::value_to_vector(v_pt2, pt2);

    ChildData* cj_data = new ChildData;
    World::Data* world_data = World::c_to_data(joint_data->m_world);

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
    cj_data->m_cur_distance = cj_data->m_cur_normal.get_length();

    if (cj_data->m_cur_distance > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_distance);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    if (joint_data->m_parent) {
        cj_data->m_dftp.m_body = joint_data->m_parent;
        world_data->m_dfts.insert(&cj_data->m_dftp);
    }
    cj_data->m_dftc.m_body = joint_data->m_child;
    world_data->m_dfts.insert(&cj_data->m_dftc);

    joint_data->m_cdata = cj_data;

    Joint::c_create_end(self, joint_data);

    c_update_info(joint_data);

    return self;
}

VALUE MSP::GenericPointToPoint::rbf_get_point1(VALUE self) {
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

VALUE MSP::GenericPointToPoint::rbf_set_point1(VALUE self, VALUE v_point) {
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

VALUE MSP::GenericPointToPoint::rbf_get_point2(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    return RU::point_to_value(matrix.transform_vector2(cj_data->m_point2));
}

VALUE MSP::GenericPointToPoint::rbf_set_point2(VALUE self, VALUE v_point) {
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

VALUE MSP::GenericPointToPoint::rbf_get_min_distance(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_min_distance * M_INCH_TO_METER);
}

VALUE MSP::GenericPointToPoint::rbf_set_min_distance(VALUE self, VALUE v_length) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_min_distance = Geom::max_treal(RU::value_to_treal(v_length), 0.0) * M_METER_TO_INCH;
    return Qnil;
}

VALUE MSP::GenericPointToPoint::rbf_get_max_distance(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_max_distance * M_INCH_TO_METER);
}

VALUE MSP::GenericPointToPoint::rbf_set_max_distance(VALUE self, VALUE v_length) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_max_distance = Geom::max_treal(RU::value_to_treal(v_length), 0.0) * M_METER_TO_INCH;
    return Qnil;
}

VALUE MSP::GenericPointToPoint::rbf_get_force(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_force * M_INCH_TO_METER);
}

VALUE MSP::GenericPointToPoint::rbf_set_force(VALUE self, VALUE v_force) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_force = RU::value_to_treal(v_force) * M_METER_TO_INCH;
    return Qnil;
}

VALUE MSP::GenericPointToPoint::rbf_get_cur_distance(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_distance * M_INCH_TO_METER);
}

VALUE MSP::GenericPointToPoint::rbf_get_cur_velocity(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_velocity * M_INCH_TO_METER);
}

VALUE MSP::GenericPointToPoint::rbf_get_cur_normal(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::vector_to_value(cj_data->m_cur_normal);
}

VALUE MSP::GenericPointToPoint::rbf_limits_enabled(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_limits_enabled);
}

VALUE MSP::GenericPointToPoint::rbf_enable_limits(VALUE self, VALUE v_state) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_limits_enabled = RU::value_to_bool(v_state);
    return Qnil;
}

VALUE MSP::GenericPointToPoint::rbf_update_info(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    c_update_info(joint_data);
    return Qnil;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::GenericPointToPoint::init_ruby(VALUE mMSP) {
    VALUE cGenericPointToPoint = rb_define_class_under(mMSP, "GenericPointToPoint", rba_cJoint);

    rb_define_alloc_func(cGenericPointToPoint, Joint::c_class_allocate);

    rb_define_const(cGenericPointToPoint, "DEFAULT_MIN_DISTANCE", RU::to_value(DEFAULT_MIN_DISTANCE));
    rb_define_const(cGenericPointToPoint, "DEFAULT_MAX_DISTANCE", RU::to_value(DEFAULT_MAX_DISTANCE));
    rb_define_const(cGenericPointToPoint, "DEFAULT_FORCE", RU::to_value(DEFAULT_FORCE));
    rb_define_const(cGenericPointToPoint, "DEFAULT_LIMITS_ENABLED", RU::to_value(DEFAULT_LIMITS_ENABLED));

    rb_define_method(cGenericPointToPoint, "initialize", VALUEFUNC(rbf_initialize), 6);
    rb_define_method(cGenericPointToPoint, "get_point1", VALUEFUNC(rbf_get_point1), 0);
    rb_define_method(cGenericPointToPoint, "set_point1", VALUEFUNC(rbf_set_point1), 1);
    rb_define_method(cGenericPointToPoint, "get_point2", VALUEFUNC(rbf_get_point2), 0);
    rb_define_method(cGenericPointToPoint, "set_point2", VALUEFUNC(rbf_set_point2), 1);
    rb_define_method(cGenericPointToPoint, "min_distance", VALUEFUNC(rbf_get_min_distance), 0);
    rb_define_method(cGenericPointToPoint, "min_distance=", VALUEFUNC(rbf_set_min_distance), 1);
    rb_define_method(cGenericPointToPoint, "max_distance", VALUEFUNC(rbf_get_max_distance), 0);
    rb_define_method(cGenericPointToPoint, "max_distance=", VALUEFUNC(rbf_set_max_distance), 1);
    rb_define_method(cGenericPointToPoint, "force", VALUEFUNC(rbf_get_force), 0);
    rb_define_method(cGenericPointToPoint, "force=", VALUEFUNC(rbf_set_force), 1);
    rb_define_method(cGenericPointToPoint, "cur_distance", VALUEFUNC(rbf_get_cur_distance), 0);
    rb_define_method(cGenericPointToPoint, "cur_velocity", VALUEFUNC(rbf_get_cur_velocity), 0);
    rb_define_method(cGenericPointToPoint, "cur_normal", VALUEFUNC(rbf_get_cur_normal), 0);
    rb_define_method(cGenericPointToPoint, "limits_enabled?", VALUEFUNC(rbf_limits_enabled), 0);
    rb_define_method(cGenericPointToPoint, "limits_enabled=", VALUEFUNC(rbf_enable_limits), 1);
    rb_define_method(cGenericPointToPoint, "update_info", VALUEFUNC(rbf_update_info), 0);
}
