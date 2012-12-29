open Ocamlbuild_plugin
open Printf
open Command

let files = ["META"; "ostatfs.cma"; "ostatfs.cmi"; "ostatfs.cmx"; "ostatfs.o"; "ostatfs.cmxa"; "ostatfs.mli"; "ostatfs.a"; "libostatfs_stubs.a"]

let rule_ocamlfind l _ _ = Cmd (S((A"ocamlfind") :: l))


let link_stubs name ?(cclib=[]) stubs =
  let stubs_lib = sprintf "lib%s.%s" stubs !Options.ext_lib in
  let stubs_dll = sprintf "dll%s.%s" stubs !Options.ext_dll in
  let cclib = List.flatten & List.map (fun lib -> ["-cclib"; lib]) & ("-l"^stubs) :: cclib in
  List.iter (fun ext ->
    let file = sprintf "file:%s.%s" name ext in
    (* embed -l option into ocaml library so that C linker can find C stubs *)
    flag ["link"; "ocaml"; "library"; file] & atomize cclib;
(*
    dep  ["link"; "ocaml"; "library"; file] [stubs_lib];
*)
    if ext = "cma" then
    begin
      (* embed -l option into ocaml library so that ocamlrun can find dll stubs *)
      flag ["link"; "ocaml"; "library"; "byte"; file] & atomize ["-dllib"; "-l" ^ stubs;];
      dep  ["link"; "ocaml"; "library"; "byte"; file] [stubs_dll]
    end
  ) ["cma"; "cmxa"]

let ocaml_lib_stubs name ?(dir="") ?(cclib=[]) stubs =
  link_stubs name ~cclib stubs;
  (* locally compiled programs (toplevel and tests) will use locally compiled library *)
  ocaml_lib name;
  (* find library locally (ocamlrun and C linker respectively) *)
  flag ["link"; "ocaml"; "byte"; "use_"^name] & atomize ["-dllpath"; !Options.build_dir / dir];
  flag ["link"; "ocaml"; "use_"^name] & atomize ["-I"; (if dir = "" then "." else dir);]


let installer_rules ~files ~name =
	ocaml_lib_stubs "ostatfs" "ostatfs_stubs";

	let deps = List.map (fun f -> f) files in
	let files = List.map (fun f -> A f) files in


	rule ("Install " ^ name) ~prod:"install" ~deps (rule_ocamlfind (A"install" :: A name :: files));
	rule ("Uninstall " ^ name) ~prod:"uninstall" ~deps:[] (rule_ocamlfind [A"remove"; A name]);
	rule ("Reinstall" ^ name) ~prod:"reinstall" ~deps:["uninstall"; "install"] (fun _ _ -> Cmd (S[A"/bin/true"]))

let _ =
	dispatch begin function
		| After_rules ->
			installer_rules ~files ~name:"ostatfs";
		| _ -> ()
	end
