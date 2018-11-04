/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_entity.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Entity::rbf_initialize(VALUE self) {
    VALUE cname = rb_class_name(CLASS_OF(self));
    rb_raise(rb_eTypeError, "%s cannot be instantiated", RSTRING_PTR(cname));
}

VALUE MSP::Entity::rbf_initialize_copy(VALUE self, VALUE orig_self) {
    VALUE cname = rb_class_name(CLASS_OF(self));
    rb_raise(rb_eTypeError, "%s cannot be duplicated", RSTRING_PTR(cname));
}

VALUE MSP::Entity::rbf_to_s(VALUE self) {
    VALUE v_cname = rb_class_name(CLASS_OF(self));
    const char* cname = RSTRING_PTR(v_cname);
    char* buffer = new char[RSTRING_LEN(v_cname) + 64];
    sprintf(buffer, "#<%s:%p>", cname, (void*)self);
    VALUE v_str = RU::to_value(buffer);
    OBJ_INFECT(v_str, self);
    delete[] buffer;
    return v_str;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Entity::init_ruby(VALUE mMSP) {
    rba_cEntity = rb_define_class_under(mMSP, "Entity", rb_cObject);

    rb_define_method(rba_cEntity, "initialize", VALUEFUNC(rbf_initialize), 0);
    rb_define_method(rba_cEntity, "initialize_copy", VALUEFUNC(rbf_initialize_copy), 1);
    rb_define_method(rba_cEntity, "to_s", VALUEFUNC(rbf_to_s), 0);
    rb_define_method(rba_cEntity, "inspect", VALUEFUNC(rbf_to_s), 0);
}
