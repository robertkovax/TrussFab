/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_contact.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Contact::c_class_allocate(VALUE klass) {
    Data* data = new Data;
    return Data_Wrap_Struct(klass, c_class_mark, c_class_deallocate, data);
}

void MSP::Contact::c_class_mark(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    rb_gc_mark(data->v_toucher);
}

void MSP::Contact::c_class_deallocate(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    delete data;
}

MSP::Contact::Data* MSP::Contact::c_to_data(VALUE self) {
    Data* data;
    Data_Get_Struct(self, Data, data);
    return data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Contact::rbf_initialize(VALUE self) {
    return self;
}

VALUE MSP::Contact::rbf_initialize_copy(VALUE self, VALUE orig_self) {
    Data* data;
    Data* orig_data;

#ifndef RUBY_VERSION18
    if (!OBJ_INIT_COPY(self, orig_self)) return self;
#endif

    Data_Get_Struct(self, Data, data);
    Data_Get_Struct(orig_self, Data, orig_data);

    data->v_toucher = orig_data->v_toucher;
    data->m_point = orig_data->m_point;
    data->m_normal = orig_data->m_normal;
    data->m_speed = orig_data->m_speed;

    return self;
}

VALUE MSP::Contact::rbf_get_toucher(VALUE self) {
    Data* data = c_to_data(self);
    return data->v_toucher;
}

VALUE MSP::Contact::rbf_get_point(VALUE self) {
    Data* data = c_to_data(self);
    return RU::point_to_value(data->m_point);
}

VALUE MSP::Contact::rbf_get_normal(VALUE self) {
    Data* data = c_to_data(self);
    return RU::vector_to_value(data->m_normal);
}

VALUE MSP::Contact::rbf_get_speed(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_speed * M_INCH_TO_METER);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Contact::init_ruby(VALUE mMSP) {
    rba_cContact = rb_define_class_under(mMSP, "Contact", rba_cEntity);

    rb_define_alloc_func(rba_cContact, c_class_allocate);

    rb_define_method(rba_cContact, "initialize", VALUEFUNC(rbf_initialize), 0);
    rb_define_method(rba_cContact, "initialize_copy", VALUEFUNC(rbf_initialize_copy), 1);

    rb_define_method(rba_cContact, "toucher", VALUEFUNC(rbf_get_toucher), 0);
    rb_define_method(rba_cContact, "point", VALUEFUNC(rbf_get_point), 0);
    rb_define_method(rba_cContact, "normal", VALUEFUNC(rbf_get_normal), 0);
    rb_define_method(rba_cContact, "speed", VALUEFUNC(rbf_get_speed), 0);
}
