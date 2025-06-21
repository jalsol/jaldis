(lang dune 3.17)

(name jaldis)

(generate_opam_files true)

(source
 (github jalsol/jaldis))

(authors "Nguyen Quang Truong <nqtruong.1002@gmail.com>")

(maintainers "Nguyen Quang Truong <nqtruong.1002@gmail.com>")

(license MIT)

(package
 (name jaldis)
 (synopsis "just a little redis clone")
 (description "it is exactly how it's named")
 (depends ocaml core async ppx_jane ocamlformat zarith angstrom))
