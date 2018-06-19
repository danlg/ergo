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

(** ErgoNNRC is an IL with function tables where the body is written in NNRC. It is the main IL interfacing with Q*cert for code-generation. *)

(** * Abstract Syntax *)

Require Import String.
Require Import ErgoSpec.Common.CTO.CTO.
Require Import ErgoSpec.Backend.ErgoBackend.

Section ErgoNNRC.

  Section Syntax.

    (** Expression *)
    Definition nnrc_expr := ErgoCodeGen.nnrc_expr.

    Record lambdan :=
      mkLambdaN
        { lambdan_params: list (string * cto_type);
          lambdan_output : cto_type;
          lambdan_body : nnrc_expr; }.

    (** Function *)
    Record nnrc_function :=
      mkFuncN
        { functionn_name : string;
          functionn_lambda : lambdan; }.

    (** Function table *)
    Record nnrc_function_table :=
      mkFuncTableN
        { function_tablen_name : string;
          function_tablen_funs : list nnrc_function; }.

    (** Declaration *)
    Inductive nnrc_declaration :=
    | ENExpr : nnrc_expr -> nnrc_declaration
    | ENGlobal : string -> nnrc_expr -> nnrc_declaration
    | ENFunc : nnrc_function -> nnrc_declaration
    | ENFuncTable : nnrc_function_table -> nnrc_declaration.

    (** Module. *)
    Record nnrc_module :=
      mkModuleN
        { modulen_namespace : string;
          modulen_declarations : list nnrc_declaration; }.

  End Syntax.

  Section Semantics.
    (* XXX Nothing yet -- relational semantics should go here *)
  End Semantics.

  Section Evaluation.
    (* XXX Nothing yet -- evaluation semantics should go here *)
  End Evaluation.
End ErgoNNRC.
