/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp.h"

#include "msp_entity.h"
#include "msp_hit.h"
#include "msp_contact.h"
#include "msp_world.h"
#include "msp_body.h"
#include "msp_joint.h"

#include "msp_fixed.h"
#include "msp_plane.h"
#include "msp_point_to_point.h"
#include "msp_point_to_point_actuator.h"
#include "msp_point_to_point_gas_spring.h"
#include "msp_generic_point_to_point.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Variables
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::rba_cEntity;
VALUE MSP::rba_cHit;
VALUE MSP::rba_cContact;
VALUE MSP::rba_cWorld;
VALUE MSP::rba_cBody;
VALUE MSP::rba_cJoint;


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::rbf_newton_version(VALUE self) {
    //return rb_sprintf("%d.%d", NEWTON_MAJOR_VERSION, NEWTON_MINOR_VERSION);
    char version_str[16];
    sprintf(version_str, "%d.%d", NEWTON_MAJOR_VERSION, NEWTON_MINOR_VERSION);
    return rb_str_new2(version_str);
}

VALUE MSP::rbf_newton_float_size(VALUE self) {
    return RU::to_value(NewtonWorldFloatSize());
}

VALUE MSP::rbf_newton_memory_used(VALUE self) {
    return RU::to_value(NewtonGetMemoryUsed());
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::init_ruby(VALUE mMSP) {
    RU::init_ruby();

    MSP::Entity::init_ruby(mMSP);
    MSP::Hit::init_ruby(mMSP);
    MSP::Contact::init_ruby(mMSP);
    MSP::World::init_ruby(mMSP);
    MSP::Body::init_ruby(mMSP);
    MSP::Joint::init_ruby(mMSP);

    MSP::Fixed::init_ruby(mMSP);
    MSP::Plane::init_ruby(mMSP);
    MSP::PointToPoint::init_ruby(mMSP);
    MSP::PointToPointActuator::init_ruby(mMSP);
    MSP::PointToPointGasSpring::init_ruby(mMSP);
    MSP::GenericPointToPoint::init_ruby(mMSP);

    rb_define_module_function(mMSP, "newton_version", VALUEFUNC(MSP::rbf_newton_version), 0);
    rb_define_module_function(mMSP, "newton_float_size", VALUEFUNC(MSP::rbf_newton_float_size), 0);
    rb_define_module_function(mMSP, "newton_memory_used", VALUEFUNC(MSP::rbf_newton_memory_used), 0);
}
