
#include <stdio.h>
#ifndef _Lang_types_h
#define _Lang_types_h

/* Definition of the supported types*/
typedef enum {type_error, 
              type_integer, type_float, type_bool,
              type_int_set, type_float_set, 
              type_par_int, type_par_float, 
              type_par_int_set, type_par_float_set
              } ParType;

#endif              
