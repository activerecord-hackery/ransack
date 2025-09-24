/*
 * pg_type_map_by_class.c - PG::TypeMapByClass class extension
 * $Id$
 *
 * This type map can be used to select value encoders based on the class
 * of the given value to be send.
 *
 */

#include "pg.h"

static VALUE rb_cTypeMapByClass;

typedef struct {
	t_typemap typemap;

	VALUE klass_to_coder;
	VALUE self;

	struct pg_tmbk_coder_cache_entry {
		VALUE klass;
		t_pg_coder *p_coder;
	} cache_row[0x100];
} t_tmbk;

/*
 * We use 8 Bits of the klass object id as index to a 256 entry cache.
 * This avoids full lookups in most cases.
 */
#define CACHE_LOOKUP(this, klass) ( &this->cache_row[(((unsigned long)klass) >> 8) & 0xff] )


static t_pg_coder *
pg_tmbk_lookup_klass(t_tmbk *this, VALUE klass, VALUE param_value)
{
	t_pg_coder *p_coder;
	struct pg_tmbk_coder_cache_entry *p_ce;

	p_ce = CACHE_LOOKUP(this, klass);

	/* Is the cache entry for the expected klass? */
	if( p_ce->klass == klass ) {
		p_coder = p_ce->p_coder;
	} else {
		/* No, then do a full lookup based on the ancestors. */
		VALUE obj = rb_hash_lookup( this->klass_to_coder, klass );

		if( NIL_P(obj) ){
			int i;
			VALUE ancestors = rb_mod_ancestors( klass );

			Check_Type( ancestors, T_ARRAY );
			/* Don't look at the first element, it's expected to equal klass. */
			for( i=1; i<RARRAY_LEN(ancestors); i++ ){
				obj = rb_hash_lookup( this->klass_to_coder, rb_ary_entry( ancestors, i) );

				if( !NIL_P(obj) )
					break;
			}
		}

		if(NIL_P(obj)){
			p_coder = NULL;
		}else if(rb_obj_is_kind_of(obj, rb_cPG_Coder)){
			TypedData_Get_Struct(obj, t_pg_coder, &pg_coder_type, p_coder);
		}else{
			if( RB_TYPE_P(obj, T_SYMBOL) ){
				/* A Symbol: Call the method with this name. */
				obj = rb_funcall(this->self, SYM2ID(obj), 1, param_value);
			}else{
				/* A Proc object (or something that responds to #call). */
				obj = rb_funcall(obj, rb_intern("call"), 1, param_value);
			}

			if( NIL_P(obj) ){
				p_coder = NULL;
			}else{
				/* Check retrieved coder type */
				TypedData_Get_Struct(obj, t_pg_coder, &pg_coder_type, p_coder);
			}

			/* We can not cache coders retrieved by ruby code, because we can not anticipate
			 * the returned Coder object. */
			return p_coder;
		}

		/* Write the retrieved coder to the cache */
		p_ce->klass = klass;
		p_ce->p_coder = p_coder;
	}
	return p_coder;
}


static t_pg_coder *
pg_tmbk_typecast_query_param( t_typemap *p_typemap, VALUE param_value, int field )
{
	t_tmbk *this = (t_tmbk *)p_typemap;
	t_pg_coder *p_coder;

  p_coder = pg_tmbk_lookup_klass( this, rb_obj_class(param_value), param_value );

	if( !p_coder ){
		t_typemap *default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
		return default_tm->funcs.typecast_query_param( default_tm, param_value, field );
	}

	return p_coder;
}

static VALUE
pg_tmbk_fit_to_query( VALUE self, VALUE params )
{
	t_tmbk *this = (t_tmbk *)RTYPEDDATA_DATA(self);
	/* Nothing to check at this typemap, but ensure that the default type map fits. */
	t_typemap *default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
	default_tm->funcs.fit_to_query( this->typemap.default_typemap, params );
	return self;
}

static void
pg_tmbk_mark( void *_this )
{
	t_tmbk *this = (t_tmbk *)_this;
	pg_typemap_mark(&this->typemap);
	rb_gc_mark_movable(this->klass_to_coder);
	rb_gc_mark_movable(this->self);
}

static size_t
pg_tmbk_memsize( const void *_this )
{
	const t_tmbk *this = (const t_tmbk *)_this;
	return sizeof(*this);
}

static void
pg_tmbk_compact(void *ptr)
{
	t_tmbk *this = (t_tmbk *)ptr;

	pg_typemap_compact(&this->typemap);
	pg_gc_location(this->klass_to_coder);
	pg_gc_location(this->self);

	/* Clear the cache, to be safe from changes of klass VALUE by GC.compact. */
	memset(&this->cache_row, 0, sizeof(this->cache_row));
}

static const rb_data_type_t pg_tmbk_type = {
	"PG::TypeMapByClass",
	{
		pg_tmbk_mark,
		RUBY_TYPED_DEFAULT_FREE,
		pg_tmbk_memsize,
		pg_tmbk_compact,
	},
	&pg_typemap_type,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED | PG_RUBY_TYPED_FROZEN_SHAREABLE,
};

static VALUE
pg_tmbk_s_allocate( VALUE klass )
{
	t_tmbk *this;
	VALUE self;

	self = TypedData_Make_Struct( klass, t_tmbk, &pg_tmbk_type, this );
	this->typemap.funcs.fit_to_result = pg_typemap_fit_to_result;
	this->typemap.funcs.fit_to_query = pg_tmbk_fit_to_query;
	this->typemap.funcs.fit_to_copy_get = pg_typemap_fit_to_copy_get;
	this->typemap.funcs.typecast_result_value = pg_typemap_result_value;
	this->typemap.funcs.typecast_query_param = pg_tmbk_typecast_query_param;
	this->typemap.funcs.typecast_copy_get = pg_typemap_typecast_copy_get;
	RB_OBJ_WRITE(self, &this->typemap.default_typemap, pg_typemap_all_strings);

	/* We need to store self in the this-struct, because pg_tmbk_typecast_query_param(),
	 * is called with the this-pointer only. */
	this->self = self;
	RB_OBJ_WRITE(self, &this->klass_to_coder, rb_hash_new());

	/* The cache is properly initialized by TypedData_Make_Struct(). */

	return self;
}

/*
 * call-seq:
 *    typemap.[class] = coder
 *
 * Assigns a new PG::Coder object to the type map. The encoder
 * is chosen for all values that are a kind of the given +class+ .
 *
 * +coder+ can be one of the following:
 * * +nil+        - Values are forwarded to the #default_type_map .
 * * a PG::Coder  - Values are encoded by the given encoder
 * * a Symbol     - The method of this type map (or a derivation) that is called for each value to sent.
 *   It must return a PG::Coder or +nil+ .
 * * a Proc       - The Proc object is called for each value. It must return a PG::Coder or +nil+ .
 *
 */
static VALUE
pg_tmbk_aset( VALUE self, VALUE klass, VALUE coder )
{
	t_tmbk *this = RTYPEDDATA_DATA( self );

	rb_check_frozen(self);

	if(NIL_P(coder)){
		rb_hash_delete( this->klass_to_coder, klass );
	}else{
		rb_hash_aset( this->klass_to_coder, klass, coder );
	}

	/* The cache lookup key can be a derivation of the klass.
	 * So we can not expire the cache selectively. */
	memset( &this->cache_row, 0, sizeof(this->cache_row) );

	return coder;
}

/*
 * call-seq:
 *    typemap.[class] -> coder
 *
 * Returns the encoder object for the given +class+
 */
static VALUE
pg_tmbk_aref( VALUE self, VALUE klass )
{
	t_tmbk *this = RTYPEDDATA_DATA( self );

	return rb_hash_lookup(this->klass_to_coder, klass);
}

/*
 * call-seq:
 *    typemap.coders -> Hash
 *
 * Returns all classes and their assigned encoder object.
 */
static VALUE
pg_tmbk_coders( VALUE self )
{
	t_tmbk *this = RTYPEDDATA_DATA( self );

	return rb_obj_freeze(rb_hash_dup(this->klass_to_coder));
}

void
init_pg_type_map_by_class(void)
{
	/*
	 * Document-class: PG::TypeMapByClass < PG::TypeMap
	 *
	 * This type map casts values based on the class or the ancestors of the given value
	 * to be sent.
	 *
	 * This type map is usable for type casting query bind parameters and COPY data
	 * for PG::Connection#put_copy_data . Therefore only encoders might be assigned by
	 * the #[]= method.
	 */
	rb_cTypeMapByClass = rb_define_class_under( rb_mPG, "TypeMapByClass", rb_cTypeMap );
	rb_define_alloc_func( rb_cTypeMapByClass, pg_tmbk_s_allocate );
	rb_define_method( rb_cTypeMapByClass, "[]=", pg_tmbk_aset, 2 );
	rb_define_method( rb_cTypeMapByClass, "[]", pg_tmbk_aref, 1 );
	rb_define_method( rb_cTypeMapByClass, "coders", pg_tmbk_coders, 0 );
	/* rb_mDefaultTypeMappable = rb_define_module_under( rb_cTypeMap, "DefaultTypeMappable"); */
	rb_include_module( rb_cTypeMapByClass, rb_mDefaultTypeMappable );
}
