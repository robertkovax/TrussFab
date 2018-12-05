/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_CONTACT_H
#define MSP_CONTACT_H

#include "msp.h"

class MSP::Contact {
public:
    // Structures
    struct Data {
        VALUE v_toucher;
        Geom::Vector3d m_point;
        Geom::Vector3d m_normal;
        treal m_speed;
        Data() :
            v_toucher(Qnil),
            m_point(0.0f),
            m_normal(0.0f),
            m_speed(0.0f)
        {
        }
    };

    // Helper Functions
    static VALUE c_class_allocate(VALUE klass);
    static void c_class_mark(void* data);
    static void c_class_deallocate(void* data);
    static Data* c_to_data(VALUE self);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self);
    static VALUE rbf_initialize_copy(VALUE self, VALUE orig_self);
    static VALUE rbf_get_toucher(VALUE self);
    static VALUE rbf_get_point(VALUE self);
    static VALUE rbf_get_normal(VALUE self);
    static VALUE rbf_get_speed(VALUE self);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_CONTACT_H */
