(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2018-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)

type t =
  | Success     (* Riscv Model with explicit success dependency *)
  | Instr       (* Define instr (or same-instance) relation *)
  | SpecialX0   (* Some events by AMO to or from x0 are not generated *)
  | NoRMW
(* Riscv: Expand load acquire and store release as fences *)
  | AcqRelAsFence
(* Backward compatibility *)
  | BackCompat
  | FullScDepend    (* Complete dependencies for Store Conditinal *)
  | SplittedRMW     (* Splitted RMW events for riscv *)
  | SwitchDepScWrite  (* Switch dependency on sc mem write, riscv, aarch64 *)
  | SwitchDepScResult  (* Switch dependency from address read to sc result register,  aarch64 *)
  | LrScDiffOk      (* Lr/Sc paired to <> addresses may succeed (!) *)
  | NotWeakPredicated (* NOT "Weak" predicated instructions, not performing non-selected events, aarch64 *)
(* Mixed size *)
  | Mixed
  | Unaligned
 (* Do not check (and reject early) mixed size tests in non-mixed-size mode *)
  | DontCheckMixed
(* Tags *)
  | MemTag
  | TagCheckPrecise
  | TagCheckUnprecise
  | TooFar
  | Morello
  | Neon
(* Branch speculation+ cat computation of dependencies *)
  | Deps
  | Instances (* Compute dependencies on instruction instances *)
  | Kvm
  | ETS
(* Do not insert branching event between pte read and accesses *)
  | NoPteBranch
(* Pte-Squared: all accesses through page table, including PT accesses *)
  | PTE2
(* Count maximal number of phantom updates by looking at loads *)
  | PhantomOnLoad
(* Optimise Rf enumeration leading to rmw *)
  | OptRfRMW
(* Allow some constrained unpredictable, behaviours.
   AArch64: LDXR / STXR of different size or address may succeed. *)
  | ConstrainedUnpredictable
(* Perform experiment *)
  | Exp
(* Instruction-fetch support (AKA "self-modifying code" mode) *)
  | Self
(* Test something *)
  | Test
(* One hundred tests *)
  | T of int


let tags =
  ["success";"instr";"specialx0";"normw";"acqrelasfence";"backcompat";
   "fullscdepend";"splittedrmw";"switchdepscwrite";"switchdepscresult";"lrscdiffok";
   "mixed";"dontcheckmixed";"weakpredicated"; "memtag";
   "tagcheckprecise"; "tagcheckunprecise"; "precise"; "imprecise";
   "toofar"; "deps"; "morello"; "instances"; "noptebranch"; "pte2";
   "pte-squared"; "PhantomOnLoad"; "OptRfRMW"; "ConstrainedUnpredictable";
   "exp"; "self"; "test"; "T[0-9][0-9]"]

let parse s = match Misc.lowercase s with
| "success" -> Some Success
| "instr" -> Some Instr
| "specialx0"|"amox0"|"x0" -> Some SpecialX0
| "normw" -> Some NoRMW
| "acqrelasfence" -> Some AcqRelAsFence
| "backcompat"|"back" -> Some BackCompat
| "fullscdepend"|"scdepend" -> Some FullScDepend
| "splittedrmw" -> Some SplittedRMW
| "switchdepscwrite" -> Some  SwitchDepScWrite
| "switchdepscresult" -> Some  SwitchDepScResult
| "lrscdiffok" -> Some  LrScDiffOk
| "mixed" -> Some Mixed
| "unaligned" -> Some Unaligned
| "dontcheckmixed" -> Some DontCheckMixed
| "notweakpredicated"|"notweakpred" -> Some NotWeakPredicated
| "tagmem"|"memtag" -> Some MemTag
| "tagcheckprecise"|"precise" -> Some TagCheckPrecise
| "tagcheckimprecise"|"imprecise" -> Some TagCheckUnprecise
| "toofar" -> Some TooFar
| "morello" -> Some Morello
| "neon" -> Some Neon
| "deps" -> Some Deps
| "instances"|"instance" -> Some Instances
| "kvm" -> Some Kvm
| "ets" -> Some ETS
| "noptebranch"|"nobranch" -> Some NoPteBranch
| "pte2" | "pte-squared" -> Some PTE2
| "phantomonload" -> Some PhantomOnLoad
| "optrfrmw" -> Some OptRfRMW
| "constrainedunpredictable"|"cu" -> Some ConstrainedUnpredictable
| "exp" -> Some Exp
| "self" -> Some Self
| "test" -> Some Test
| s ->
   if String.length s = 3 then
     match s.[0],s.[1],s.[2] with
     | 't', ('0'..'9' as c1),('0'..'9' as c2) ->
        let n =
          (Char.code c1 - Char.code '0')*10 +
            (Char.code c2 - Char.code '0') in
        Some (T n)
     | _ -> None
   else None

let pp = function
  | Success -> "success"
  | Instr -> "instr"
  | SpecialX0 -> "specialx0"
  | NoRMW -> "normw"
  | AcqRelAsFence -> "acqrelasfence"
  | BackCompat ->"backcompat"
  | FullScDepend -> "FullScDepend"
  | SplittedRMW -> "SplittedRWM"
  | SwitchDepScWrite -> "SwitchDepScWrite"
  | SwitchDepScResult -> "SwitchDepScResult"
  | LrScDiffOk -> " LrScDiffOk"
  | Mixed -> "mixed"
  | Unaligned -> "unaligned"
  | DontCheckMixed -> "DontCheckMixed"
  | NotWeakPredicated -> "NotWeakPredicated"
  | MemTag -> "memtag"
  | TagCheckPrecise -> "TagCheckPrecise"
  | TagCheckUnprecise -> "TagCheckImprecise"
  | TooFar -> "TooFar"
  | Morello -> "Morello"
  | Neon -> "Neon"
  | Deps -> "Deps"
  | Instances -> "Instances"
  | Kvm -> "kvm"
  | ETS -> "ets"
  | NoPteBranch -> "NoPteBranch"
  | PTE2 -> "pte-squared"
  | PhantomOnLoad -> "PhantomOnLoad"
  | OptRfRMW -> "OptRfRMW"
  | ConstrainedUnpredictable -> "ConstrainedUnpredictable"
  | Exp -> "exp"
  | Self -> "self"
  | Test -> "test"
  | T n -> Printf.sprintf "T%02i" n

let compare = compare

let get_default a v =
  try match v with
  | SwitchDepScWrite ->
      begin match a with
      | `RISCV(*|`AArch64*) -> true
      | _ -> false
      end
  | SwitchDepScResult ->
      begin match a with
      | `AArch64 -> false
      | _ -> true
      end
  | _ -> raise Exit
  with Exit -> Warn.fatal "No default for variant %s" (pp v)

let get_switch a v f =
  let d = get_default a v in
  if f v then not d else d

let set_precision r tag =
    try
      r :=
        (match tag with
        | TagCheckPrecise -> true
        | TagCheckUnprecise -> false
        | _ -> raise Exit) ;
      true
    with Exit -> false
