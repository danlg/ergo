(*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

(** Translates ErgoNNRC to JavaScript *)

Require Import String.
Require Import List.

Require Import ErgoSpec.Version.
Require Import ErgoSpec.Utils.Misc.
Require Import ErgoSpec.Common.Result.
Require Import ErgoSpec.Common.Names.
Require Import ErgoSpec.ErgoNNRC.Lang.ErgoNNRC.
Require Import ErgoSpec.Backend.ErgoBackend.

Section ErgoNNRCtoJavaScript.
  Local Open Scope estring_scope.

  (** Top-level expression *)
  Definition javascript_of_expression
             (e:nnrc_expr)                  (* expression to translate *)
             (t : nat)                      (* next available unused temporary *)
             (i : nat)                      (* indentation level *)
             (eol:estring)                   (* Choice of end of line character *)
             (quotel:estring)                (* Choice of quote character *)
    : ErgoCodeGen.ejavascript
      * ErgoCodeGen.ejavascript
      * nat
    := ErgoCodeGen.nnrc_expr_javascript_unshadow e t i eol quotel nil nil.

  (** Top-level constant *)
  Definition javascript_of_constant
             (v:string)                     (* constant name *)
             (bind:nnrc_expr)               (* expression computing the constant *)
             (t : nat)                      (* next available unused temporary *)
             (i : nat)                      (* indentation level *)
             (eol:estring)                   (* Choice of end of line character *)
             (quotel:estring)                (* Choice of quote character *)
    : ErgoCodeGen.ejavascript
      * ErgoCodeGen.ejavascript
      * nat
    := 
      let '(s1, e1, t2) := ErgoCodeGen.nnrc_expr_to_javascript bind t i eol quotel nil in
      let v0 := `ErgoCodeGen.javascript_identifier_sanitizer ("v" ++ v) in
      (s1 +++ (ErgoCodeGen.javascript_indent i) +++ `"var " +++ v0 +++ `" = " +++ e1 +++ `";" +++ eol,
       v0,
       t2).

  (** Single method *)
  Definition javascript_method_of_body
             (e:nnrc_expr)
             (fname:string)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    let input_v := "context"%string in
    ErgoCodeGen.nnrc_expr_to_javascript_method input_v e 1 eol quotel (input_v::nil)
                                               (ErgoCodeGen.javascript_identifier_sanitizer fname).

  (** Single function *)
  Definition javascript_function_of_body
             (e:nnrc_expr)
             (fname:string)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    let input_v := "context"%string in
    let init_indent := 0 in
    ErgoCodeGen.nnrc_expr_to_javascript_fun_lift e (ErgoCodeGen.javascript_identifier_sanitizer fname) input_v init_indent eol quotel.

  Definition javascript_function_of_nnrc_function
             (f:nnrc_function)
             (tname:option string)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    let fname := function_name_in_table tname f.(functionn_name) in
    javascript_function_of_body f.(functionn_lambda).(lambdan_body) fname eol quotel.

  Definition javascript_functions_of_nnrc_functions
             (fl:list nnrc_function)
             (tname:option string)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    emulti_append eol (fun f => javascript_function_of_nnrc_function f tname eol quotel) fl.

  Definition javascript_method_of_nnrc_function
             (f:nnrc_function)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    let fname := f.(functionn_name) in
    javascript_method_of_body f.(functionn_lambda).(lambdan_body) fname eol quotel.
    
  Definition javascript_methods_of_nnrc_functions
             (fl:list nnrc_function)
             (tname:string)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    emulti_append eol (fun f => javascript_method_of_nnrc_function f eol quotel) fl.

  Definition es5_of_nnrc_function_table
             (ft:nnrc_function_table)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    (* let tname := ErgoCodeGen.javascript_identifier_sanitizer ft.(function_tablen_name) in *)
    let tname := None in
    javascript_functions_of_nnrc_functions ft.(function_tablen_funs) tname eol quotel +++ eol.

  Definition es6_of_nnrc_function_table
             (ft:nnrc_function_table)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    let tname := ErgoCodeGen.javascript_identifier_sanitizer ft.(function_tablen_name) in
    `"class " +++ `tname +++ `" {" +++ eol
              +++ (javascript_methods_of_nnrc_functions ft.(function_tablen_funs) tname eol quotel) +++ eol
              +++ `"}" +++ eol.

  Definition javascript_of_nnrc_function_table
             (version:jsversion)
             (ft:nnrc_function_table)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    match version with
    | ES5 => es5_of_nnrc_function_table ft eol quotel
    | ES6 => es6_of_nnrc_function_table ft eol quotel
    end.

  Definition preamble (eol:estring) : estring :=
    `"" +++ `"/* Generated using ergoc version " +++ `ergo_version +++ `" */" +++ eol
        +++ `"'use strict';" +++ eol
        +++ `"/*eslint-disable no-unused-vars*/" +++ eol
        +++ `"/*eslint-disable no-undef*/" +++ eol
        +++ `"/*eslint-disable no-var*/" +++ eol
        +++ eol.

  Definition postamble (eol:estring) :=
    `"" +++ eol
        +++ `"/*eslint-enable no-unused-vars*/" +++ eol
        +++ `"/*eslint-enable no-undef*/" +++ eol
         +++ eol.
    
  Definition javascript_of_declaration
             (version:jsversion)
             (s : nnrc_declaration)   (* statement to translate *)
             (t : nat)                (* next available unused temporary *)
             (i : nat)                (* indentation level *)
             (eol : estring)
             (quotel : estring)
    : ErgoCodeGen.ejavascript          (* JavaScript statements for computing result *)
      * ErgoCodeGen.ejavascript        (* JavaScript expression holding result *)
      * nat                           (* next available unused temporary *)
    :=
      match s with
      | DNExpr e => javascript_of_expression e t i eol quotel
      | DNConstant v e => javascript_of_constant v e t i eol quotel
      | DNFunc f => (javascript_function_of_nnrc_function f None eol quotel,`"null",t)
      | DNFuncTable ft => (javascript_of_nnrc_function_table version ft eol quotel,`"null",t)
      end.

  Definition javascript_of_declarations
             (version:jsversion)
             (sl : list nnrc_declaration) (* statements to translate *)
             (t : nat)                    (* next available unused temporary *)
             (i : nat)                    (* indentation level *)
             (eol : estring)
             (quotel : estring)
    : ErgoCodeGen.ejavascript
    := let proc_one
             (s:nnrc_declaration)
             (acc:ErgoCodeGen.ejavascript * nat) : ErgoCodeGen.ejavascript * nat :=
           let '(s0, t0) := acc in
           let '(s1, e1, t1) := javascript_of_declaration version s t0 i eol quotel in
           (s0 +++ s1,
            t1) (* XXX Ignores e1! *)
       in
       let '(sn, tn) := fold_right proc_one (`"",t) sl in
       sn.

  Definition javascript_of_inheritance
             (inheritance:list (string * string))
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    `"" +++ `"var inheritance = " +++ eol
        +++ (ENNRCtoJavaScript.inheritanceToJS quotel inheritance)
        +++ `";" +++ eol
        +++ eol.
  
  Definition nnrc_module_to_javascript
             (version:jsversion)
             (inheritance: list (string*string))
             (p:nnrc_module)
             (eol:estring)
             (quotel:estring) : ErgoCodeGen.ejavascript :=
    (preamble eol) +++ eol
                   +++ (javascript_of_inheritance inheritance eol quotel)
                   +++ (javascript_of_declarations version p.(modulen_declarations) 0 0 eol quotel)
                   +++ (postamble eol).

  Definition nnrc_module_to_javascript_top
             (version:jsversion)
             (inheritance: list (string*string))
             (p:nnrc_module) : ErgoCodeGen.ejavascript :=
    nnrc_module_to_javascript version inheritance p ErgoCodeGen.javascript_eol_newline ErgoCodeGen.javascript_quotel_double.

End ErgoNNRCtoJavaScript.

