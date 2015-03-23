Require Import FiatToFacade.Compiler.Prerequisites.
Require Import Bedrock.Platform.Facade.examples.FiatADTs.
Require Import List GLabelMap.

Unset Implicit Arguments.

(* Inversion lemmas *)
Require Import Bedrock.Platform.Facade.DFacade.

Ltac runsto_prelude :=
  intros;
  inversion_facade; simpl in *; autoinj; [ | congruence];
  eq_transitive; autoinj;
  unfold sel in *; simpl in *;
  autodestruct; subst;
  try subst_find; simpl in *; autoinj; (* TODO Make autoinj call simpl in * first *)
  repeat (match goal with
            | H: 0 = length ?a |- _ => destruct a; [|discriminate]
            | H: S _ = length ?a |- _ => destruct a; [congruence|]
          end; simpl in *; autoinj; simpl in *).

Lemma runsto_pop :
  forall hd tl (vseq thead: StringMap.key) env (st st': State ADTValue) f,
    vseq <> thead ->
    st [vseq >> ADT (List (hd :: tl))] ->
    GLabelMap.find (elt:=FuncSpec _) f env = Some (Axiomatic List_pop) ->
    RunsTo env (Call thead f (vseq :: nil)) st st' ->
    StringMap.Equal st' (StringMap.add thead (SCA _ hd) (StringMap.add vseq (ADT (List tl)) st)).
Proof.
  runsto_prelude.
Qed.

Lemma runsto_rev :
  forall env seq st st' vseq f tret,
    st [vseq >> ADT (List seq)] ->
    GLabelMap.find (elt:=FuncSpec _) f env = Some (Axiomatic List_rev) ->
    RunsTo env (Call tret f (vseq :: nil)) st st' ->
    StringMap.Equal st' ([tret >> SCAZero]::[vseq >adt> List (rev seq)]::st).
Proof.
  runsto_prelude.
Qed.

Lemma runsto_is_empty :
  forall seq (vseq tis_empty: StringMap.key) env (st st': State ADTValue) f,
    vseq <> tis_empty ->
    st [vseq >> ADT (List seq)] ->
    GLabelMap.find (elt:=FuncSpec _) f env = Some (Axiomatic List_empty) ->
    RunsTo env (Call tis_empty f (vseq :: nil)) st st' ->
    exists ret,
      ((ret = SCAZero /\ seq <> nil) \/ (ret = SCAOne /\ seq = nil)) /\
      StringMap.Equal st' (StringMap.add tis_empty ret st).
Proof.
  runsto_prelude.

  unfold Programming.propToWord in *.
  unfold IF_then_else in *.

  destruct H5; eexists; split; intuition;
  etransitivity; try eassumption;
  setoid_rewrite add_noop_mapsto at 2; try eassumption;
  subst; reflexivity.
Qed.

Lemma runsto_copy :
  forall seq (vseq vcopy: StringMap.key) env (st st': State ADTValue) f,
    st [vseq >> ADT (List seq)] ->
    GLabelMap.find (elt:=FuncSpec _) f env = Some (Axiomatic List_copy) ->
    RunsTo env (Call vcopy f (vseq :: nil)) st st' ->
    StringMap.Equal st' (StringMap.add vcopy (ADT (List seq)) (StringMap.add vseq (ADT (List seq)) st)).
Proof.
  runsto_prelude.
Qed.

Lemma runsto_delete :
  forall seq (vseq vret: StringMap.key) env (st st': State ADTValue) f,
    st [vseq >> ADT (List seq)] ->
    GLabelMap.find (elt:=FuncSpec _) f env = Some (Axiomatic List_delete) ->
    RunsTo env (Call vret f (vseq :: nil)) st st' ->
    StringMap.Equal st' (StringMap.add vret SCAZero (StringMap.remove vseq st)).
Proof.
  runsto_prelude.
Qed.

Lemma runsto_cons :
  forall seq head (vseq vhead vdiscard: StringMap.key) env (st st': State ADTValue) f,
    st [vseq >> ADT (List seq)] ->
    st [vhead >> SCA _ head] ->
    GLabelMap.find (elt:=FuncSpec _) f env = Some (Axiomatic List_push) ->
    RunsTo env (Call vdiscard f (vseq :: vhead :: nil)) st st' ->
    StringMap.Equal st' (StringMap.add vdiscard (SCA _ 0) (StringMap.add vseq (ADT (List (head :: seq))) st)).
Proof.
  runsto_prelude.
  subst_find; simpl in *; autoinj.
Qed.

Lemma runsto_new :
  forall env st1 st2 vret f,
    GLabelMap.find (elt:=FuncSpec _) f env = Some (Axiomatic List_new) ->
    RunsTo env (Call vret f nil) st1 st2 ->
    StringMap.Equal st2 ([vret >adt> List nil]::st1).
Proof.
  runsto_prelude.
Qed.