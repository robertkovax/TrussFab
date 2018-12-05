/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_ENTITY_H
#define MSP_ENTITY_H

#include "msp.h"

class MSP::Entity {
public:
    // Ruby Functions
    static VALUE rbf_initialize(VALUE self);
    static VALUE rbf_initialize_copy(VALUE self, VALUE orig_self);
    static VALUE rbf_to_s(VALUE self);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_WORLD_H */
