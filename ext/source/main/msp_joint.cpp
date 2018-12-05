/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_joint.h"
#include "msp_world.h"
#include "msp_body.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::Joint::DEFAULT_STIFFNESS(1.0);
const treal MSP::Joint::DEFAULT_STIFFNESS_RANGE(500.0);
const treal MSP::Joint::DEFAULT_BREAKING_FORCE(0.0);
const treal MSP::Joint::CUSTOM_LARGE_VALUE(1.0e15);
const int MSP::Joint::DEFAULT_SOLVER_MODEL(0);
const bool MSP::Joint::DEFAULT_BODIES_COLLIDABLE(false);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Joint::c_class_allocate(VALUE klass) {
    Data* joint_data = new Data;
    return Data_Wrap_Struct(klass, c_class_mark, c_class_deallocate, joint_data);
}

void MSP::Joint::c_class_mark(void* data_ptr) {
    Data* joint_data = reinterpret_cast<Data*>(data_ptr);
    rb_gc_mark(joint_data->v_group);
}

void MSP::Joint::c_class_deallocate(void* data_ptr) {
    Data* joint_data = reinterpret_cast<Data*>(data_ptr);
    if (joint_data->m_joint)
        NewtonDestroyJoint(joint_data->m_world, joint_data->m_joint);
    delete joint_data;
}

MSP::Joint::Data* MSP::Joint::c_to_data(VALUE v_joint) {
    Data* data;
    //Data_Get_Struct(self, Data, joint_data);
    data = reinterpret_cast<Data*>(DATA_PTR(v_joint));
    if (data->m_joint == nullptr) {
        VALUE cname = rb_class_name(CLASS_OF(v_joint));
        rb_raise(rb_eTypeError, "Reference to deleted %s", RSTRING_PTR(cname));
    }
    return data;
}

MSP::Joint::Data* MSP::Joint::c_to_data(const NewtonJoint* joint) {
    return reinterpret_cast<Data*>(NewtonJointGetUserData(joint));
}

MSP::Joint::Data* MSP::Joint::c_to_data_simple_cast(VALUE v_joint) {
    return reinterpret_cast<Data*>(DATA_PTR(v_joint));
}

MSP::Joint::Data* MSP::Joint::c_create_begin(
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
    OnAdjustPinMatrix on_adjust_pin_matrix)
{
    Data* joint_data;
    World::Data* world_data;
    const NewtonBody* parent_body;
    const NewtonBody* child_body;
    Geom::Transformation pin_tra, parent_tra;

    Data_Get_Struct(self, Data, joint_data);

    world_data = World::c_to_data_type_check(v_world);

    if (v_matrix != Qnil) {
        RU::value_to_transformation3(v_matrix, pin_tra);
        pin_tra.normalize_self();

        if (pin_tra.is_flipped())
            pin_tra.m_xaxis.reverse_self();
    }
    else {
        pin_tra.m_xaxis = Geom::Vector3d::X_AXIS;
        pin_tra.m_yaxis = Geom::Vector3d::Y_AXIS;
        pin_tra.m_zaxis = Geom::Vector3d::Z_AXIS;
        pin_tra.m_origin = Geom::Vector3d::ORIGIN;
    }

    if (v_parent != Qnil)
        parent_body = World::c_value_to_body(world_data, v_parent);
    else
        parent_body = nullptr;

    child_body = MSP::World::c_value_to_body(world_data, v_child);

    if (child_body == parent_body)
        rb_raise(rb_eTypeError, "Using same body as parent and child is not allowed!");

    if (v_group != Qnil && rb_obj_is_kind_of(v_group, RU::SU_GROUP) == Qfalse && rb_obj_is_kind_of(v_group, RU::SU_COMPONENT_INSTANCE) == Qfalse) {
        VALUE cname1 = rb_class_name(RU::SU_GROUP);
        VALUE cname2 = rb_class_name(RU::SU_COMPONENT_INSTANCE);
        rb_raise(rb_eTypeError, "Expected %s, %s, or nil", RSTRING_PTR(cname1), RSTRING_PTR(cname2));
    }

    if (parent_body) {
        NewtonBodyGetMatrix(parent_body, &parent_tra[0][0]);
        joint_data->m_pin_matrix = pin_tra * parent_tra.inverse();
    }
    else {
        joint_data->m_pin_matrix = pin_tra;
    }

    joint_data->m_world = world_data->m_world;
    joint_data->m_parent = parent_body;
    joint_data->m_child = child_body;
    joint_data->v_group = v_group;
    joint_data->v_self = self;
    joint_data->m_dof = dof;
    joint_data->m_on_update = on_update;
    joint_data->m_on_destroy = on_destroy;
    joint_data->m_on_breaking_force_changed = on_breaking_force_changed;
    joint_data->m_on_adjust_pin_matrix = on_adjust_pin_matrix;

    return joint_data;
}

void MSP::Joint::c_create_end(VALUE self, Data* joint_data) {
    World::Data* world_data = World::c_to_data(joint_data->m_world);

    c_update_breaking_info(joint_data);
    c_update_local_matrix(joint_data);

    joint_data->m_joint = NewtonConstraintCreateUserJoint(world_data->m_world, joint_data->m_dof, submit_constraints, joint_data->m_child, joint_data->m_parent);
    NewtonJointSetCollisionState(joint_data->m_joint, joint_data->m_bodies_collidable ? 1 : 0);
    NewtonUserJointSetSolverModel(joint_data->m_joint, joint_data->m_solver_model);
    NewtonJointSetUserData(joint_data->m_joint, joint_data);
    NewtonJointSetDestructor(joint_data->m_joint, constraint_destructor);

    world_data->m_joints[joint_data->m_joint] = self;
}

void MSP::Joint::c_update_breaking_info(Data* joint_data) {
    if (joint_data->m_breaking_force > M_EPSILON) {
        joint_data->m_breaking_force_sq = joint_data->m_breaking_force * joint_data->m_breaking_force;
        joint_data->m_limit_min_row_proc = do_limit_min_row;
        joint_data->m_limit_max_row_proc = do_limit_max_row;
    }
    else {
        joint_data->m_breaking_force = 0.0;
        joint_data->m_breaking_force_sq = 0.0;
        joint_data->m_limit_min_row_proc = do_nothing;
        joint_data->m_limit_max_row_proc = do_nothing;
    }
    if (joint_data->m_on_breaking_force_changed)
        joint_data->m_on_breaking_force_changed(joint_data);
}

void MSP::Joint::c_update_local_matrix(Data* joint_data) {
    Geom::Transformation pin_matrix, matrix0, matrix1;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix0[0][0]);
    // Joint pin matrix with respect to parent body
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix1[0][0]);
        pin_matrix = joint_data->m_pin_matrix * matrix1;
        joint_data->m_local_matrix2 = pin_matrix * matrix1.inverse();
    }
    else {
        pin_matrix = joint_data->m_pin_matrix;
        joint_data->m_local_matrix2 = pin_matrix;
    }
    // Adjust joint pin matrix
    if (joint_data->m_on_adjust_pin_matrix)
        joint_data->m_on_adjust_pin_matrix(joint_data, pin_matrix);
    // Adjusted joint pin matrix with respect to child body
    joint_data->m_local_matrix0 = pin_matrix * matrix0.inverse();
    // Adjusted joint pin matrix with respect to parent body
    if (joint_data->m_parent)
        joint_data->m_local_matrix1 = pin_matrix * matrix1.inverse();
    else
        joint_data->m_local_matrix1 = pin_matrix;
}

void MSP::Joint::c_calculate_global_matrix(Data* joint_data, Geom::Transformation& matrix0, Geom::Transformation& matrix1) {
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    matrix0 = joint_data->m_local_matrix0 * matrix;
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        matrix1 = joint_data->m_local_matrix1 * matrix;
    }
    else
        matrix1 = joint_data->m_local_matrix1;
}

void MSP::Joint::c_calculate_global_matrix2(Data* joint_data, Geom::Transformation& matrix0, Geom::Transformation& matrix1, Geom::Transformation& matrix2) {
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    matrix0 = joint_data->m_local_matrix0 * matrix;
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        matrix1 = joint_data->m_local_matrix1 * matrix;
        matrix2 = joint_data->m_local_matrix2 * matrix;
    }
    else {
        matrix1 = joint_data->m_local_matrix1;
        matrix2 = joint_data->m_local_matrix2;
    }
}

void MSP::Joint::c_calculate_global_parent_matrix(Data* joint_data, Geom::Transformation& parent_matrix) {
    if (joint_data->m_parent) {
        Geom::Transformation matrix;
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        parent_matrix = joint_data->m_local_matrix1 * matrix;
    }
    else
        parent_matrix = joint_data->m_local_matrix1;
}

void MSP::Joint::c_calculate_angle(const Geom::Vector3d& dir, const Geom::Vector3d& cosDir, const Geom::Vector3d& sinDir, treal& sinAngle, treal& cosAngle) {
    cosAngle = dir.dot(cosDir);
    sinAngle = (dir.cross(cosDir)).dot(sinDir);
}

treal MSP::Joint::c_calculate_angle2(const Geom::Vector3d& dir, const Geom::Vector3d& cosDir, const Geom::Vector3d& sinDir, treal& sinAngle, treal& cosAngle) {
    cosAngle = dir.dot(cosDir);
    sinAngle = (dir.cross(cosDir)).dot(sinDir);
    return atan2(sinAngle, cosAngle);
}

treal MSP::Joint::c_calculate_angle2(const Geom::Vector3d& dir, const Geom::Vector3d& cosDir, const Geom::Vector3d& sinDir) {
    treal sinAngle, cosAngle;
    return c_calculate_angle2(dir, cosDir, sinDir, sinAngle, cosAngle);
}

void MSP::Joint::c_get_pin_matrix(Data* joint_data, Geom::Transformation& matrix_out) {
    Geom::Transformation parent_matrix;
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &parent_matrix[0][0]);
        matrix_out = joint_data->m_pin_matrix * parent_matrix;
    }
    else
        matrix_out = joint_data->m_pin_matrix;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Joint::submit_constraints(const NewtonJoint* joint, treal timestep, int thread_index) {
    Data* joint_data = c_to_data(joint);
    // Update
    if (timestep > M_EPSILON) {
        joint_data->m_on_update(joint_data, joint, timestep, thread_index);
    }

    // Destroy constraint if force exceeds particular limit
    if (joint_data->m_breaking_force > M_EPSILON && joint_data->m_tension1.get_length_squared() > joint_data->m_breaking_force_sq) {
        World::Data* world_data = World::c_to_data(joint_data->m_world);
        NewtonWorldCriticalSectionLock(joint_data->m_world, thread_index);
        world_data->m_joints_to_destroy.push_back(joint);
        NewtonWorldCriticalSectionUnlock(joint_data->m_world);
    }
}

void MSP::Joint::constraint_destructor(const NewtonJoint* joint) {
    Data* joint_data = c_to_data(joint);
    World::Data* world_data = World::c_to_data(joint_data->m_world);
    if (joint_data->m_on_destroy)
        joint_data->m_on_destroy(joint_data);
    if (world_data->m_joints.find(joint) != world_data->m_joints.end())
        world_data->m_joints.erase(joint);
    joint_data->m_joint = nullptr;
    joint_data->m_world = nullptr;
    joint_data->m_parent = nullptr;
    joint_data->m_child = nullptr;
}

void MSP::Joint::do_limit_min_row(Data* joint_data) {
    NewtonUserJointSetRowMinimumFriction(joint_data->m_joint, -joint_data->m_breaking_force);
}

void MSP::Joint::do_limit_max_row(Data* joint_data) {
    NewtonUserJointSetRowMaximumFriction(joint_data->m_joint, joint_data->m_breaking_force);
}

void MSP::Joint::do_nothing(Data* joint_data) {
    // Do nothing
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Joint::rbf_is_valid(VALUE self) {
    Data* data;
    Data_Get_Struct(self, Data, data);
    return data->m_joint ? Qtrue : Qfalse;
}

VALUE MSP::Joint::rbf_destroy(VALUE self) {
    Data* data = c_to_data(self);
    NewtonDestroyJoint(data->m_world, data->m_joint);
    return Qnil;
}

VALUE MSP::Joint::rbf_get_group(VALUE self) {
    Data* data = c_to_data(self);
    return data->v_group;
}

VALUE MSP::Joint::rbf_get_world(VALUE self) {
    Data* data = c_to_data(self);
    World::Data* world_data = World::c_to_data(data->m_world);
    return world_data->v_self;
}

VALUE MSP::Joint::rbf_get_parent(VALUE self) {
    Data* joint_data = c_to_data(self);
    if (joint_data->m_parent) {
        Body::Data* body_data = Body::c_to_data(joint_data->m_parent);
        return body_data->v_self;
    }
    else
        return Qnil;
}

VALUE MSP::Joint::rbf_get_child(VALUE self) {
    Data* joint_data = c_to_data(self);
    if (joint_data->m_child) {
        Body::Data* body_data = Body::c_to_data(joint_data->m_child);
        return body_data->v_self;
    }
    else
        return Qnil;
}

VALUE MSP::Joint::rbf_get_breaking_force(VALUE self) {
    Data* joint_data = c_to_data(self);
    return RU::to_value(joint_data->m_breaking_force * M_INCH_TO_METER);
}

VALUE MSP::Joint::rbf_set_breaking_force(VALUE self, VALUE v_force_mag) {
    Data* joint_data = c_to_data(self);
    joint_data->m_breaking_force = Geom::max_treal(RU::value_to_treal(v_force_mag), 0.0) * M_METER_TO_INCH;
    c_update_breaking_info(joint_data);
    return Qnil;
}

VALUE MSP::Joint::rbf_get_stiffness(VALUE self) {
    Data* joint_data = c_to_data(self);
    return RU::to_value(joint_data->m_stiffness);
}

VALUE MSP::Joint::rbf_set_stiffness(VALUE self, VALUE v_stiffness) {
    Data* joint_data = c_to_data(self);
    joint_data->m_stiffness = Geom::clamp_treal(RU::value_to_treal(v_stiffness), 0.0, 1.0);
    return Qnil;
}

VALUE MSP::Joint::rbf_get_solver_model(VALUE self) {
    Data* joint_data = c_to_data(self);
    return RU::to_value(joint_data->m_solver_model);
}

VALUE MSP::Joint::rbf_set_solver_model(VALUE self, VALUE v_solver_model) {
    Data* joint_data = c_to_data(self);
    joint_data->m_solver_model = Geom::clamp_int(RU::value_to_int(v_solver_model), 0, 2);;
    NewtonUserJointSetSolverModel(joint_data->m_joint, joint_data->m_solver_model);
    return Qnil;
}

VALUE MSP::Joint::rbf_get_bodies_collidable_state(VALUE self) {
    Data* joint_data = c_to_data(self);
    return RU::to_value(joint_data->m_bodies_collidable);
}

VALUE MSP::Joint::rbf_set_bodies_collidable_state(VALUE self, VALUE v_state) {
    Data* joint_data = c_to_data(self);
    joint_data->m_bodies_collidable = RU::value_to_bool(v_state);
    NewtonJointSetCollisionState(joint_data->m_joint, joint_data->m_bodies_collidable ? 1 : 0);
    return Qnil;
}

VALUE MSP::Joint::rbf_get_linear_tension(VALUE self) {
    Data* joint_data = c_to_data(self);
    return RU::vector_to_value2(joint_data->m_tension1, M_INCH_TO_METER);
}

VALUE MSP::Joint::rbf_get_angular_tension(VALUE self) {
    Data* joint_data = c_to_data(self);
    return RU::vector_to_value2(joint_data->m_tension2, M_INCH2_TO_METER2);
}

VALUE MSP::Joint::rbf_get_pin_matrix(VALUE self) {
    Data* joint_data = c_to_data(self);
    if (joint_data->m_parent) {
        Geom::Transformation parent_matrix;
        NewtonBodyGetMatrix(joint_data->m_parent, &parent_matrix[0][0]);
        return RU::transformation_to_value(joint_data->m_pin_matrix * parent_matrix);
    }
    else
        return RU::transformation_to_value(joint_data->m_pin_matrix);
}

VALUE MSP::Joint::rbf_set_pin_matrix(VALUE self, VALUE v_pin_matrix) {
    Data* joint_data = c_to_data(self);
    Geom::Transformation pin_matrix, parent_matrix;

    RU::value_to_transformation3(v_pin_matrix, pin_matrix);

    pin_matrix.normalize_self();
    if (pin_matrix.is_flipped())
        pin_matrix.m_xaxis.reverse_self();

    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &parent_matrix[0][0]);
        joint_data->m_pin_matrix = pin_matrix * parent_matrix.inverse();
    }
    else
        joint_data->m_pin_matrix = pin_matrix;

    c_update_local_matrix(joint_data);

    return Qnil;
}

VALUE MSP::Joint::rbf_get_pin_matrix2(VALUE self, VALUE v_mode) {
    Data* joint_data = c_to_data(self);
    Geom::Transformation matrix1, matrix2;
    int mode = RU::value_to_int(v_mode);

    if (mode == 0) {
        NewtonBodyGetMatrix(joint_data->m_child, &matrix1[0][0]);
        matrix2 = joint_data->m_local_matrix0 * matrix1;
        return RU::transformation_to_value(matrix2);
    }
    else if (mode == 1) {
        if (joint_data->m_parent) {
            NewtonBodyGetMatrix(joint_data->m_parent, &matrix1[0][0]);
            matrix2 = joint_data->m_local_matrix1 * matrix1;
            return RU::transformation_to_value(matrix2);
        }
        else
            return RU::transformation_to_value(joint_data->m_local_matrix1);
    }
    else {
        if (joint_data->m_parent) {
            NewtonBodyGetMatrix(joint_data->m_parent, &matrix1[0][0]);
            matrix2 = joint_data->m_local_matrix2 * matrix1;
            return RU::transformation_to_value(matrix2);
        }
        else
            return RU::transformation_to_value(joint_data->m_local_matrix2);
    }
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Joint::init_ruby(VALUE mMSP) {
    rba_cJoint = rb_define_class_under(mMSP, "Joint", rba_cEntity);

    rb_define_const(rba_cJoint, "DEFAULT_STIFFNESS", RU::to_value(DEFAULT_STIFFNESS));
    rb_define_const(rba_cJoint, "DEFAULT_SOLVER_MODEL", RU::to_value(DEFAULT_SOLVER_MODEL));
    rb_define_const(rba_cJoint, "DEFAULT_BODIES_COLLIDABLE", RU::to_value(DEFAULT_BODIES_COLLIDABLE));
    rb_define_const(rba_cJoint, "DEFAULT_BREAKING_FORCE", RU::to_value(DEFAULT_BREAKING_FORCE));

    //rb_define_alloc_func(rba_cJoint, c_class_allocate);
    //rb_define_singleton_method(rba_cJoint, "new", rbf_new, 0);

    rb_define_method(rba_cJoint, "valid?", VALUEFUNC(rbf_is_valid), 0);
    rb_define_method(rba_cJoint, "destroy", VALUEFUNC(rbf_destroy), 0);
    rb_define_method(rba_cJoint, "group", VALUEFUNC(rbf_get_group), 0);
    rb_define_method(rba_cJoint, "world", VALUEFUNC(rbf_get_world), 0);
    rb_define_method(rba_cJoint, "parent", VALUEFUNC(rbf_get_parent), 0);
    rb_define_method(rba_cJoint, "child", VALUEFUNC(rbf_get_child), 0);

    rb_define_method(rba_cJoint, "breaking_force", VALUEFUNC(rbf_get_breaking_force), 0);
    rb_define_method(rba_cJoint, "breaking_force=", VALUEFUNC(rbf_set_breaking_force), 1);
    rb_define_method(rba_cJoint, "stiffness", VALUEFUNC(rbf_get_stiffness), 0);
    rb_define_method(rba_cJoint, "stiffness=", VALUEFUNC(rbf_set_stiffness), 1);
    rb_define_method(rba_cJoint, "solver_model", VALUEFUNC(rbf_get_solver_model), 0);
    rb_define_method(rba_cJoint, "solver_model=", VALUEFUNC(rbf_set_solver_model), 1);
    rb_define_method(rba_cJoint, "bodies_collidable?", VALUEFUNC(rbf_get_bodies_collidable_state), 0);
    rb_define_method(rba_cJoint, "bodies_collidable=", VALUEFUNC(rbf_set_bodies_collidable_state), 1);

    rb_define_method(rba_cJoint, "linear_tension", VALUEFUNC(rbf_get_linear_tension), 0);
    rb_define_method(rba_cJoint, "angular_tension", VALUEFUNC(rbf_get_angular_tension), 0);

    rb_define_method(rba_cJoint, "get_pin_transformation", VALUEFUNC(rbf_get_pin_matrix), 0);
    rb_define_method(rba_cJoint, "get_pin_transformation2", VALUEFUNC(rbf_get_pin_matrix2), 1);
    rb_define_method(rba_cJoint, "set_pin_transformation", VALUEFUNC(rbf_set_pin_matrix), 1);
}
