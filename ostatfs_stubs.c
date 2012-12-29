
#include <stdio.h>
#include <unistd.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>

#include <sys/vfs.h>

CAMLprim value
caml_statfs(value ml_path)
{
	CAMLparam1 (ml_path);
	CAMLlocal1 (ret);

	struct statfs sf;
	char *path = String_val (ml_path);

	if (!statfs(path, &sf) == 0) {
		 caml_failwith("statfs error");
	}

	ret = caml_alloc (5, 0);
	Store_field (ret, 0, copy_int64 (sf.f_blocks));
	Store_field (ret, 1, copy_int64 (sf.f_bfree));
	Store_field (ret, 2, copy_int64 (sf.f_bavail));
	Store_field (ret, 3, copy_int64 (sf.f_files));
	Store_field (ret, 4, copy_int64 (sf.f_ffree));

	CAMLreturn (ret);
}
