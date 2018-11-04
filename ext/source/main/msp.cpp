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
#include "msp_gear.h"

#include "msp_fixed.h"
#include "msp_point_to_point.h"
#include "msp_point_to_point_actuator.h"
#include "msp_point_to_point_gas_spring.h"
#include "msp_generic_point_to_point.h"

/*#include "msp_newton.h"
#include "msp_world.h"
#include "msp_collision.h"
#include "msp_body.h"
#include "msp_bodies.h"
#include "msp_joint.h"
#include "msp_gear.h"

#include "msp_joint_ball_and_socket.h"
#include "msp_joint_corkscrew.h"
#include "msp_joint_fixed.h"
#include "msp_joint_hinge.h"
#include "msp_joint_motor.h"
#include "msp_joint_piston.h"
#include "msp_joint_servo.h"
#include "msp_joint_slider.h"
#include "msp_joint_spring.h"
#include "msp_joint_universal.h"
#include "msp_joint_up_vector.h"
#include "msp_joint_curvy_slider.h"
#include "msp_joint_curvy_piston.h"
#include "msp_joint_plane.h"
#include "msp_joint_point_to_point.h"

#ifdef MSP_USE_SDL
    #include "msp_sdl.h"
    #include "msp_sdl_mixer.h"
    #include "msp_sound.h"
    #include "msp_music.h"
    #include "msp_joystick.h"
#endif

#include "msp_particle.h"*/

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
VALUE MSP::rba_cGear;


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::rbf_is_sdl_used(VALUE self) {
#ifdef MSP_USE_SDL
    return Qtrue;
#else
    return Qfalse;
#endif
}

VALUE MSP::rbf_about_c_ext(VALUE self) {
    VALUE v_str = RU::to_value("Copyright (c) Anton Synytsia, 20 February 2018");
    OBJ_INFECT(v_str, self);
    return v_str;
}

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
    MSP::Gear::init_ruby(mMSP);

    MSP::Fixed::init_ruby(mMSP);
    MSP::PointToPoint::init_ruby(mMSP);
    MSP::PointToPointActuator::init_ruby(mMSP);
    MSP::PointToPointGasSpring::init_ruby(mMSP);
    MSP::GenericPointToPoint::init_ruby(mMSP);

    rb_define_module_function(mMSP, "sdl_used?", VALUEFUNC(MSP::rbf_is_sdl_used), 0);
    rb_define_module_function(mMSP, "about_c_ext", VALUEFUNC(MSP::rbf_about_c_ext), 0);
    rb_define_module_function(mMSP, "newton_version", VALUEFUNC(MSP::rbf_newton_version), 0);
    rb_define_module_function(mMSP, "newton_float_size", VALUEFUNC(MSP::rbf_newton_float_size), 0);
    rb_define_module_function(mMSP, "newton_memory_used", VALUEFUNC(MSP::rbf_newton_memory_used), 0);

    /*VALUE mNewton = rb_define_module_under(mMSPhysics, "Newton");
    VALUE mC = rb_define_module_under(mMSPhysics, "C");

    Util::init_ruby();

    MSP::Newton::init_ruby(mNewton);
    MSP::World::init_ruby(mNewton);
    MSP::Collision::init_ruby(mNewton);
    MSP::Body::init_ruby(mNewton);
    MSP::Bodies::init_ruby(mNewton);
    MSP::Joint::init_ruby(mNewton);
    MSP::Gear::init_ruby(mNewton);

    MSP::BallAndSocket::init_ruby(mNewton);
    MSP::Corkscrew::init_ruby(mNewton);
    MSP::Fixed::init_ruby(mNewton);
    MSP::Hinge::init_ruby(mNewton);
    MSP::Motor::init_ruby(mNewton);
    MSP::Servo::init_ruby(mNewton);
    MSP::Slider::init_ruby(mNewton);
    MSP::Piston::init_ruby(mNewton);
    MSP::Spring::init_ruby(mNewton);
    MSP::UpVector::init_ruby(mNewton);
    MSP::Universal::init_ruby(mNewton);
    MSP::CurvySlider::init_ruby(mNewton);
    MSP::CurvyPiston::init_ruby(mNewton);
    MSP::Plane::init_ruby(mNewton);
    MSP::PointToPoint::init_ruby(mNewton);

    #ifdef MSP_USE_SDL
        MSP::SDL::init_ruby(mMSPhysics);
        MSP::SDLMixer::init_ruby(mMSPhysics);
        MSP::Sound::init_ruby(mMSPhysics);
        MSP::Music::init_ruby(mMSPhysics);
        MSP::Joystick::init_ruby(mMSPhysics);
    #endif

    MSP::Particle::init_ruby(mC);*/
}
