
let () =
	let open Ostatfs in
	let v = statfs "/" in
	Printf.printf "blocks = %Li, bfee = %Li, files = %Li, ffree = %Li\n" v.blocks v.bfree v.files v.ffree
