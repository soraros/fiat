Require Import
        Coq.Sets.Ensembles
        Coq.Classes.Morphisms
        Coq.Classes.SetoidTactics
        Fiat.Computation
        Fiat.Computation.SetoidMorphisms.

Record funSig :=
  { funDom : list Type;
    funCod : Type }.

Fixpoint funType
         (fDom : list Type)
         (fCod : Type)
         {struct fDom}
  : Type :=
  match fDom with
  | nil => Comp fCod
  | cons T fDom' => T -> funType fDom' fCod
  end.

Fixpoint cfunType
         (fDom : list Type)
         (fCod : Type)
         {struct fDom}
  : Type :=
  match fDom with
  | nil => fCod
  | cons T fDom' => T -> cfunType fDom' fCod
  end.

Definition funDef (fSig : funSig) :=
  funType (funDom fSig) (funCod fSig).

Fixpoint refineFun
         {fDom : list Type}
         {fCod : Type}
         (fSet' fSet : funType fDom fCod)
         {struct fDom} : Prop :=
  match fDom as fDom' return
        funType fDom' fCod
        -> funType fDom' fCod
        -> Prop
  with
  | nil =>
    fun fSet' fSet => refine fSet' fSet
  | cons T fDom' =>
    fun fSet' fSet =>
      forall (t : T), refineFun (fSet' t) (fSet t)
  end fSet' fSet.

Lemma refineFun_refl
      {fDom : list Type}
      {fCod : Type}
  : forall (fDef : funType fDom fCod),
    refineFun fDef fDef.
Proof.
  induction fDom; simpl; intros.
  - reflexivity.
  - eauto.
Qed.

Lemma refineFun_trans
      {fDom : list Type}
      {fCod : Type}
  : forall (fDef fDef' fDef'' : funType fDom fCod),
    refineFun fDef fDef'
    -> refineFun fDef' fDef''
    -> refineFun fDef fDef''.
Proof.
  induction fDom; simpl; intros.
  - rewrite H; eauto.
  - eauto.
Qed.

Definition refineEquivFun
           {fDom : list Type}
           {fCod : Type}
           (fSet' fSet : funType fDom fCod)
  : Prop :=
  refineFun fSet fSet' /\ refineFun fSet' fSet.

Fixpoint FunMax
         {fDom : list Type}
         {fCod : Type}
         (fSet' fSet : funType fDom fCod)
         {struct fDom} : funType fDom fCod :=
  match fDom as fDom' return
        funType fDom' fCod
        -> funType fDom' fCod
        -> funType fDom' fCod
  with
  | nil =>
    fun fSet' fSet => @Intersection _ fSet' fSet
  | cons T fDom' =>
    fun fSet' fSet =>
      (fun (t : T) => FunMax (fSet' t) (fSet t))
  end fSet' fSet.

Fixpoint FunMin
         {fDom : list Type}
         {fCod : Type}
         (fSet' fSet : funType fDom fCod)
         {struct fDom} : funType fDom fCod :=
  match fDom as fDom' return
        funType fDom' fCod
        -> funType fDom' fCod
        -> funType fDom' fCod
  with
  | nil =>
    fun fSet' fSet => @Union _ fSet' fSet
  | cons T fDom' =>
    fun fSet' fSet =>
      (fun (t : T) => FunMin (fSet' t) (fSet t))
  end fSet' fSet.

Module LeastFixedPointFun.
  Require Import Fiat.Common.Frame.

  Instance funDefOps
           {fDom : list Type}
           {fCod : Type}
    : Fiat.Common.Frame.Lattice.Ops (funType fDom fCod) :=
    { le := refineFun;
      eq := refineEquivFun;
      max := FunMax;
      min := FunMin
    }.

  Instance PreO_refineFun
           {fDom : list Type}
           {fCod : Type}
    : PreO.t (@refineFun fDom fCod) :=
    { le_refl := refineFun_refl;
      le_trans := refineFun_trans }.

  Lemma refineFun_Proper
        {fDom : list Type}
        {fCod : Type}
    : Proper (refineEquivFun ==> refineEquivFun ==> iff)
             (@refineFun fDom fCod).
  Proof.
    unfold Proper, respectful; intros.
    destruct H; destruct H0; intuition intros.
    eapply refineFun_trans; eauto.
    eapply refineFun_trans; eauto.
    eapply refineFun_trans; eauto.
    eapply refineFun_trans; eauto.
  Qed.

  Lemma refineFun_antisym
        {fDom : list Type}
        {fCod : Type}
    : forall (x y : funType fDom fCod),
      refineFun x y -> refineFun y x ->
      refineEquivFun x y.
  Proof.
    unfold refineEquivFun; intuition.
  Qed.

  Instance PO_refineFun
           {fDom : list Type}
           {fCod : Type}
    : PO.t (@refineFun fDom fCod) refineEquivFun :=
    { PreO := PreO_refineFun;
      le_proper := refineFun_Proper;
      le_antisym := refineFun_antisym}.

  Local Transparent computes_to.

  Lemma funMax_Proper
        {fDom : list Type}
        {fCod : Type}
    : Proper (@refineEquivFun
                fDom fCod
                ==> @refineEquivFun fDom fCod
                ==> @refineEquivFun fDom fCod)
             FunMax.
  Proof.
    unfold refineEquivFun, Proper, respectful; intuition.
    - induction fDom; simpl in *.
      + intros c Comp_v; destruct Comp_v.
        apply H0 in H; apply H2 in H4;
        constructor; eauto.
      + intros. eapply IHfDom; eauto.
    - induction fDom; simpl in *.
      + intros c Comp_v; destruct Comp_v.
        apply H1 in H; apply H3 in H4;
        constructor; eauto.
      + intros. eapply IHfDom; eauto.
  Qed.

  Lemma funMin_Proper
        {fDom : list Type}
        {fCod : Type}
    : Proper (@refineEquivFun
                fDom fCod
                ==> @refineEquivFun fDom fCod
                ==> @refineEquivFun fDom fCod)
             FunMin.
  Proof.
    unfold refineEquivFun, Proper, respectful; intuition.
    - induction fDom; simpl in *.
      + intros c Comp_v; destruct Comp_v.
        * constructor; apply H0; auto.
        * constructor 2; apply H2; auto.
      + intros; eapply IHfDom; eauto.
    - induction fDom; simpl in *.
      + intros c Comp_v; destruct Comp_v.
        * constructor; apply H1; auto.
        * constructor 2; apply H3; auto.
      + intros; eapply IHfDom; eauto.
  Qed.

  Lemma FunMax_ok
        {fDom : list Type}
        {fCod : Type}
    : forall l r : funType fDom fCod,
      PreO.max (le := refineFun) l r (FunMax l r).
  Proof.
    constructor.
    - induction fDom; simpl in *.
      + intros v Comp_v; destruct Comp_v; eauto.
      + eauto.
    - induction fDom; simpl in *.
      + intros v Comp_v; destruct Comp_v; eauto.
      + eauto.
    - induction fDom; simpl in *.
      + intros.
        intros v Comp_v; econstructor.
        * apply H; eauto.
        * apply H0; eauto.
      + intros; eapply IHfDom; eauto.
  Qed.

  Lemma FunMin_ok
        {fDom : list Type}
        {fCod : Type}
    : forall l r : funType fDom fCod,
      PreO.min (le := refineFun) l r (FunMin l r).
  Proof.
    constructor.
    - induction fDom; simpl in *.
      + intros v Comp_v; econstructor; eauto.
      + eauto.
    - induction fDom; simpl in *.
      + intros v Comp_v; econstructor 2; eauto.
      + eauto.
    - induction fDom; simpl in *.
      + intros.
        intros v Comp_v; destruct Comp_v.
        * apply H; eauto.
        * apply H0; eauto.
      + intros; eapply IHfDom; eauto.
  Qed.

  Instance Lattice_funDef
           {fDom : list Type}
           {fCod : Type}
    : Lattice.t _ (@funDefOps fDom fCod) :=
    { PO := PO_refineFun;
      max_proper := funMax_Proper;
      max_ok := FunMax_ok;
      min_proper := funMin_Proper;
      min_ok := FunMin_ok
    }.

  Fixpoint unCurry_funType
           (fDom : list Type)
    : Type :=
    match fDom with
    | nil => unit
    | cons T fDom' => prod T (unCurry_funType fDom')
    end.

  Fixpoint unCurry
           (fDom : list Type)
           {fCod : Type}
           (f : funType fDom fCod)
           {struct fDom}
    : funType (cons (unCurry_funType fDom) nil) fCod :=
    match fDom return
          funType fDom fCod
          -> funType (cons (unCurry_funType fDom) nil) fCod
    with
    | nil => fun f _ => f
    | cons T fDom' => fun f t => unCurry fDom' (f (fst t)) (snd t)
    end f.

  Fixpoint Curry
           (fDom : list Type)
           {fCod : Type}
           (f : funType (cons (unCurry_funType fDom) nil) fCod)
           {struct fDom}
    : funType fDom fCod :=
    match fDom return
          funType (cons (unCurry_funType fDom) nil) fCod
          -> funType fDom fCod
    with
    | nil => fun f => f tt
    | cons T fDom' => fun f t => Curry _ (fun t' => f (t, t'))
    end f.

  Lemma refineFunEquiv_Curry
        (fDom : list Type)
        {fCod : Type}
    : forall (f : funType (cons (unCurry_funType fDom) nil) fCod),
      refineEquivFun f (unCurry _ (Curry _ f)).
  Proof.
    induction fDom; simpl.
    - split; simpl; intros; destruct t; apply PreOrder_Reflexive.
    - simpl in *; split; simpl; intros.
      + destruct t; simpl in *.
        eapply (IHfDom (fun u => f (a0, u))).
      + destruct t; simpl in *.
        eapply (IHfDom (fun u => f (a0, u))).
  Qed.

  Lemma refineFunEquiv_unCurry
        (fDom : list Type)
        {fCod : Type}
    : forall (f : funType fDom fCod),
      refineEquivFun f (Curry _ (unCurry _ f)).
  Proof.
    induction fDom; simpl.
    - split; simpl; intros; apply PreOrder_Reflexive.
    - simpl in *; split; simpl; intros.
      + eapply (IHfDom (f t)).
      + eapply (IHfDom (f t)).
  Qed.

  Lemma refineFun_Curry'
        (fDom : list Type)
        {fCod : Type}
    : forall (f f' : funType (cons (unCurry_funType fDom) nil) fCod),
      refineFun f f'
      -> refineFun (Curry _ f) (Curry _ f').
  Proof.
    induction fDom; simpl.
    - intros; simpl in *; eauto.
    - simpl in *; intros.
      + eapply IHfDom; intros; eauto.
  Qed.

  Lemma refineFunEquiv_Curry'
        (fDom : list Type)
        {fCod : Type}
    : forall (f f' : funType (cons (unCurry_funType fDom) nil) fCod),
      refineEquivFun f f'
      -> refineEquivFun (Curry _ f) (Curry _ f').
  Proof.
    induction fDom; simpl.
    - split; intros; destruct H; simpl in *; eauto.
    - split; destruct H; simpl in *; intros.
      + eapply IHfDom; split; intros; eauto.
        * simpl in *; intros; eauto.
        * simpl in *; intros; eauto.
      + eapply IHfDom; split; intros; eauto.
        * simpl in *; intros; eauto.
        * simpl in *; intros; eauto.
  Qed.

    Lemma refineFunEquiv_unCurry'
        (fDom : list Type)
        {fCod : Type}
    : forall (f f' : funType fDom fCod),
      refineEquivFun f f'
      -> refineEquivFun (unCurry _ f) (unCurry _ f').
  Proof.
    induction fDom; simpl.
    - split; intros; destruct H; simpl in *; eauto.
    - split; destruct H; simpl in *; intros.
      + eapply IHfDom; split; intros; eauto.
      + eapply IHfDom; split; intros; eauto.
  Qed.

    Lemma refineFun_unCurry
        (fDom : list Type)
        {fCod : Type}
    : forall (f f' : funType fDom fCod),
      refineFun f f'
      -> refineFun (unCurry _ f) (unCurry _ f').
  Proof.
    induction fDom; simpl.
    - intros; eauto.
    - intros.
      eapply IHfDom; eauto.
  Qed.

  Lemma refineFun_unCurry'
        (fDom : list Type)
        {fCod : Type}
    : forall (f f' : funType fDom fCod),
      refineFun (unCurry _ f) (unCurry _ f')
      -> refineFun f f'.
  Proof.
    induction fDom; simpl.
    - intros; eapply (H tt).
    - intros.
      eapply IHfDom; eauto.
      simpl; intros.
      eapply (H (t, t0)).
  Qed.

  Fixpoint refineFun_lift
           (fDom : list Type)
           {fCod : Type}
           {struct fDom}
    : ((funType fDom fCod -> Prop) -> Prop) -> funType fDom fCod :=
    match fDom return
          ((funType fDom fCod -> Prop) -> Prop)
          -> funType fDom fCod with
    | nil => fun LFP_P v => (LFP_P (fun cv => computes_to cv v))
    | cons T fDom' =>
      fun LFP_P =>
        fun (t : T) => refineFun_lift fDom' (fun cv => LFP_P (fun cv' => cv (cv' t)))
    end.

  Definition refineFun_inf
             {fDom : list Type}
             {fCod : Type}
             (f : funType fDom fCod -> Prop)
    : funType fDom fCod :=
    refineFun_lift fDom (fun z => (forall s, f s -> z s)).

  Lemma refineEquivFun_lift
             {fDom : list Type}
             {fCod : Type}
    : forall (f : (funType fDom fCod -> Prop) -> Prop),
      refineEquivFun
        (refineFun_lift fDom f)
        (Curry _ (refineFun_lift _ (fun p : funType (cons (unCurry_funType fDom) nil) fCod -> Prop => f (fun f' => p (unCurry _ f' ))))).
  Proof.
    induction fDom; simpl.
    - intros; split; apply refineFun_refl.
    - simpl; split; simpl; intros.
      destruct (IHfDom (fun f' => f (fun a' => f' (a' t)))); simpl in *.
      eapply H.
      destruct (IHfDom (fun f' => f (fun a' => f' (a' t)))); simpl in *.
      eapply H0.
  Qed.

  Lemma lub_refineFun_inf
        (fDom : list Type)
        {fCod : Type}
        (f : funType fDom fCod -> Prop)
    : lub f (refineFun_inf f).
  Proof.
    unfold refineFun_inf.
    unfold lub; split.
    - simpl; intros.
      eapply refineFun_trans; [ | eapply refineEquivFun_lift].
      simpl.
      + eapply refineFun_trans.
        eapply refineFunEquiv_unCurry.
        eapply refineFun_Curry'.
        simpl. unfold refine, computes_to.
        intros; eauto.
    - simpl; intros.
      eapply refineFun_trans; [ eapply refineEquivFun_lift | ].
      eapply refineFun_unCurry'.
      simpl; intros.
      eapply PreOrder_Transitive.
      eapply (proj1 (refineFunEquiv_Curry  _ _)).
      simpl.
      unfold refine, computes_to; intros.
      eapply H in H1.
      eapply (refineFun_unCurry _ _ _ H1); eauto.
  Qed.

  Definition refineFun_sup
           {fDom : list Type}
           {fCod : Type}
           (f : funType fDom fCod -> Prop)
    : funType fDom fCod :=
    refineFun_lift fDom (fun z => exists s, f s /\ z s).

  Definition glb_refineFun_sup
             (fDom : list Type)
             {fCod : Type}
             (f : funType fDom fCod -> Prop)
    : glb f (refineFun_sup f).
  Proof.
    unfold refineFun_sup.
    unfold glb; split.
    - simpl; intros.
      eapply refineFun_trans; [ eapply refineEquivFun_lift | ].
      simpl.
      eapply refineFun_trans.
      eapply refineFun_Curry'.
      simpl; unfold refine, computes_to.
      intros; eauto.
      eapply refineFunEquiv_unCurry.
    - simpl; intros.
      eapply refineFun_trans; [ | eapply refineEquivFun_lift ].
      eapply refineFun_unCurry'.
      simpl; intros.
      unfold refine, computes_to; intros.
      pose proof (proj2 (refineFunEquiv_Curry _ _) t _ H0).
      simpl in H1; unfold computes_to in H1; destruct H1;
        intuition.
      apply H in H2.
      eapply refineFun_unCurry in H2; apply H2; eauto.
  Qed.

  Instance CompleteLattice_funDef
           {fDom : list Type}
           {fCod : Type}
    :  CompleteLattice (O := @funDefOps fDom fCod) :=
    { cl_sup := refineFun_sup;
      cl_inf := refineFun_inf
    }.
  Proof.
    eapply glb_refineFun_sup.
    eapply lub_refineFun_inf.
  Defined.

  Definition LeastFixedPoint
             {fDom : list Type}
             {fCod : Type}
             (fDef : funType fDom fCod -> funType fDom fCod)
    : funType fDom fCod :=
    (cl_sup (prefixed_point fDef)).

  Instance PreOrder_refineFun
           {fDom : list Type}
           {fCod : Type}
    : PreOrder (@refineFun fDom fCod).
  Proof.
    constructor.
    unfold Reflexive; apply refineFun_refl.
    unfold Transitive; apply refineFun_trans.
  Qed.

  Lemma refine_LeastFixedPoint
        {fDom : list Type}
        {fCod : Type}
        (fDef fDef' : funType fDom fCod -> funType fDom fCod)
      : respectful (@refineFun fDom fCod)
                   (@refineFun fDom fCod)
                   fDef fDef'
        ->
        forall (fDef_monotone : forall rec rec',
                   refineFun rec rec'
                   -> refineFun (fDef rec) (fDef rec'))
               (fDef'_monotone : forall rec rec',
                   refineFun rec rec'
                   -> refineFun (fDef' rec) (fDef' rec')),
        refineFun (LeastFixedPoint fDef)
                     (LeastFixedPoint fDef').
  Proof.
    unfold LeastFixedPoint, respectful; intros.
    destruct (sup_glb (prefixed_point fDef)) as [? ?];
      destruct (sup_glb (prefixed_point fDef')) as [? ?];
      simpl in *.
    eapply refineFun_trans.
    eapply (H0 (fDef (refineFun_sup (prefixed_point fDef')))).
    eapply fDef_monotone.
    eapply refineFun_trans.
    eapply H.
    eapply refineFun_refl.
    pose proof (proj2 (Is_LeastFixedPoint (O := @funDefOps fDom fCod) _ (fDef'_monotone))); eapply H4.
    eapply refineFun_trans.
    eapply H.
    eapply refineFun_refl.
    pose proof (proj2 (Is_LeastFixedPoint (O := @funDefOps fDom fCod) _ (fDef'_monotone))); eapply H4.
  Qed.

  Definition FibonacciSpec
    : funType ((nat : Type) :: @nil Type)%list nat :=
    LeastFixedPoint (fDom := (nat : Type) :: @nil Type)%list
                      (fun rec (n : nat) =>
                         match n with
                         | 0 => ret 0
                         | 1 => ret 1
                         | S (S n') =>
                           n1 <- rec n';
                             n2 <- rec (S n');
                             ret (n1 + n2)
                         end).

  Fixpoint FibonacciImpl
           (n : nat)
    : Comp nat :=
    match n with
    | 0 => ret 0
    | (S p) =>
      match p with
      | 0 => ret 1
      | (S m) => n1 <- FibonacciImpl p;
                   n2 <- FibonacciImpl m;
                   ret (n1 + n2)
      end
    end.

  Lemma foo
    : refineFun FibonacciSpec FibonacciImpl.
  Proof.
    eapply refineFun_trans.
    eapply refine_LeastFixedPoint; intros.
    unfold respectful; simpl; intros.

  Abort.
  (* Focus 3.

    unfold refineFun; unfold refine; intros.
    unfold FibonacciSpec, LeastFixedPoint''; simpl.
    unfold LeastFixedPointP, FixedPointP, computes_to; simpl.
    exists FibonacciImpl; split; eauto.
    clear H.
    intuition.
    admit.
    admit.
    admit.
  Admitted. *)
(*rewrite H1.
    induction t0.
    - reflexivity.
    - simpl.
      assert (refine (fSet' t0) (FibonacciImpl t0)).
      intros; rewrite H1.
      apply IHt0.
      revert H.
      destruct t0; intros.
      * reflexivity.
      * simpl in *.
        setoid_rewrite H.
        intros v' Comp_v'.
        computes_to_inv; subst.
        rewrite H1.
        eapply BindComputes with (a := v1);
        repeat computes_to_econstructor.
        2: apply Comp_v'.
        2: rewrite plus_comm; repeat computes_to_econstructor.


        eapply H1 in IHt0.
      assert (refine
                (match t0 with
                 | 0 => ret 1
                 | S m => n1 <- match t0 with
                                | 0 => ret 0
                                | 1 => ret 1
                                | S (S n') => n1 <- fSet' n';
                                              n2 <- fSet' (S n');
                                              ret (n1 + n2)
                                end;
                          n2 <- FibonacciImpl m;
                          ret (n1 + n2)
                 end)
                match t0 with
                | 0 => ret 1
                | S m => n1 <- FibonacciImpl t0;
                         n2 <- FibonacciImpl m;
                         ret (n1 + n2)
     end).
      destruct t0.
      reflexivity.
      rewrite IHt0.
      reflexivity.
      etransitivity; try eauto.
      clear H.

      apply
      rewrite <- IHt0.
      induction t0.
    reflexivity.
    rewrite H1.
    setoid_rewrite H1.
    rewrite <- IHt0.
    destruct t0.
    Focus 2.

    unfold FibonacciImpl.
    unfold
    - induction t0; simpl in *.
      + simpl; reflexivity.
      + induction t0.
        reflexivity.
        rewrite <- IHt0.

        intros v Comp_v; computes_to_inv.
        subst.
        apply IHt in Comp_v.
        computes_to_econstructor; eauto.
        destruct t.
        computes_to_econstructor; eauto.
        rewrite plus_comm; computes_to_econstructor.
        simpl in *.
        computes_to_inv; subst.
        repeat computes_to_econstructor.
        apply Comp_v'0.
        apply Comp_v.
        rewrite plus_assoc.
        rewrite plus_comm.
        rewrite (plus_comm v1 v2).
        rewrite plus_assoc.
        computes_to_econstructor; eauto.
      + induction t.
        * reflexivity.
        * simpl.
          destruct t; eauto.
          reflexivity.
          rewrite IHt.
          induction t.
          intros v Comp_v.
          simpl in *; computes_to_inv; subst.
          repeat computes_to_econstructor; eauto.
          simpl in *.
          simpl in
          apply IHt in Comp_v.
          computes_to_econstructor; eauto.
          destruct t.
          computes_to_econstructor; eauto.
          rewrite plus_comm; computes_to_econstructor.
          simpl in *.
          computes_to_inv; subst.
          repeat computes_to_econstructor.
          apply Comp_v'0.
          apply Comp_v.
          rewrite plus_assoc.
          rewrite plus_comm.
          rewrite (plus_comm v1 v2).
          rewrite plus_assoc.
          computes_to_econstructor; eauto.

        reflexivity.
        simpl.

        setoid_rewrite <- IHt.
      intros.

        simpl.

    - unfold FibonacciSpec, LeastFixedPoint''; simpl.
        unfold LeastFixedPointP, FixedPointP; simpl.
      unfold refine; intros.
      computes_to_inv; subst.
      unfold computes_to; intuition.
      eexists.
    - unfold FibonacciSpec, LeastFixedPointFun in *; simpl in *.
      destruct t.
      + unfold refine, LeastFixedPoint; simpl; intros.
        computes_to_inv; subst.
        unfold computes_to; intuition.
      + simpl in *.
        rewrite <- IHt.
        clear.
        destruct t; simpl.

  Lemma refine_LeastFixedPoint''
        {fDom : list Type}
        {fCod : Type}
        (fDef fDef' : funType fDom fCod -> funType fDom fCod)
        (f_monotone : forall rec rec',
            refineFun rec rec'
            -> refineFun (fDef rec) (fDef rec'))
      : respectful (@refineFun fDom fCod)
                   (@refineFun fDom fCod)
                   fDef fDef'
        -> refineFun (LeastFixedPoint'' fDef)
                     (LeastFixedPoint'' fDef').
  Proof.
    induction fDom; simpl; intros.
    - unfold LeastFixedPoint''; simpl in *.
      unfold refine; intros v Comp_v; intuition.
      unfold computes_to, FixedPointP, respectful in *; simpl in *.
      destruct Comp_v as [Fix' [LFP_Fix' computes_to_v] ].
      unfold LeastFixedPointP, FixedPointP in LFP_Fix'; simpl in *;
        intuition.
      exists Fix'; split; eauto.
      unfold LeastFixedPointP, FixedPointP; repeat split.
      simpl.
      etransitivity; eauto.
      Focus 3.
      simpl.
      apply H1.



      simpl in *.
      unfold FixedPoint

      exists (LeastFixedPoint fDef).
      unfold LeastFixedPointP; repeat split.
      + apply refine_LeastFixedPoint; admit.
      + apply refine_LeastFixedPoint; admit.
      + unfold FixedPointP; intros; simpl in *.
        intros v' Comp_v'.
        unfold LeastFixedPoint in Comp_v'.
        apply H0; apply Comp_v'.
      + unfold LeastFixedPoint; intros.
        destruct Comp_v; intuition.
        rewrite H; try reflexivity.
        unfold LeastFixedPointP in H1; simpl in *.
        intuition.
        unfold FixedPointP in H0.
        admit.
    - simpl in *.
      pose (
      unfold respectful in H.
      rewrite IHfDom.
      unfold LeastFixedPoint''; simpl.

      eapply IHfDom; eauto.
      unfold respectful in *; intros.
      eapply H.
      intro.
      apply H0.
  Qed.
 *)
  End LeastFixedPointFun.
