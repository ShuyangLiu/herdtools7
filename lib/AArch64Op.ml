(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2021-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)

type t =
  | AF (* get AF from PTE entry *)
  | SetAF (* set AF to 1 in PTE entry *)
  | DB (* get DB from PTE entry *)
  | SetDB (* set DB to 1 in PTE entry *)
  | DBM (* get DBM from PTE entry *)
  | Valid (* get Valid bit from PTE entry *)
  | EL0 (* get EL0 bit from PTE entry *)
  | OA (* get OA from PTE entry *)

module Make(S:Scalar.S) =
  struct

    type op1 = t

    let pp_op1 _hexa = function
      | AF -> "AF"
      | SetAF -> "SetAF"
      | DB -> "DB"
      | SetDB -> "SetDB"
      | DBM -> "DBM"
      | Valid -> "Valid"
      | EL0 -> "EL0"
      | OA -> "OA"


    type scalar = S.t
    type pteval = AArch64PteVal.t
    type cst = (scalar,pteval) Constant.t


    open AArch64PteVal

    let boolToCst =
      let open Constant in
      let zero = Concrete S.zero
      and one = Concrete S.one in
      fun b -> if b then one else zero

    let op_get_pteval op (v:cst) =
      let open Constant in
      match v with
      | PteVal p -> Some (boolToCst (op p))
      | _ -> None

    let op_set_pteval op (v:cst) =
      let open Constant in
      match v with
      | PteVal p -> Some (PteVal (op p))
      | _ -> None

    let getaf = op_get_pteval (fun p -> p.af <> 0)
    let setaf = op_set_pteval (fun p -> { p with af=1; })

    let getdb = op_get_pteval (fun p -> p.db <> 0)
    let setdb = op_set_pteval (fun p -> { p with db=1; })

    let getdbm = op_get_pteval (fun p -> p.dbm <> 0)

    let getvalid = op_get_pteval (fun p -> p.valid <> 0)

    let getel0 = op_get_pteval (fun p -> p.el0 <> 0)

    let getoa v =
      let open Constant in
      match v with
      | PteVal {oa;_} -> Some (Symbolic (oa2symbol oa))
      | _ -> None

    let do_op1 = function
      | AF -> getaf
      | SetAF -> setaf
      | DB -> getdb
      | SetDB -> setdb
      | DBM -> getdbm
      | Valid -> getvalid
      | EL0 -> getel0
      | OA -> getoa

    let shift_address_right s c =
      let open Constant in
      if S.equal (S.of_int 12) c then Some (Symbolic (System (TLB,s)))
      else None

    let mask_valid = S.one
    let mask_db = S.shift_left S.one 7
    let mask_af = S.shift_left S.one 10
    let mask_dbm = S.shift_left S.one 51
    let mask_all_neg =
      S.lognot
        (S.logor
           (S.logor mask_valid  mask_db)
           (S.logor  mask_af  mask_dbm))

    let is_zero v = S.equal S.zero v
    let is_set v m = not (is_zero (S.logand v m))

    let orop p m =
      if is_set m  mask_all_neg then None
      else
        let p = if is_set m mask_valid then { p with valid=1; } else p in
        let p = if is_set m mask_db then { p with db=0; } else p in
        let p = if is_set m mask_af then { p with af=1; } else p in
        let p = if is_set m mask_dbm then { p with dbm=1; } else p in
        Some p

    and andnot2 p m =
      if is_set m  mask_all_neg then None
      else
        let p = if is_set m mask_valid then { p with valid=0; } else p in
        let p = if is_set m mask_db then { p with db=1; } else p in
        let p = if is_set m mask_af then { p with af=0; } else p in
        let p = if is_set m mask_dbm then { p with dbm=0; } else p in
        Some p

    let mask c sz =
      let open MachSize in
      let open Constant in
      match c,sz with
      | (PteVal _,Quad)
      | (Instruction _,(Word|Quad))
        -> Some c
      | _,_ -> None
  end
