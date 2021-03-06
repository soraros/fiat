Require Import
        Fiat.Common.ilist
        Fiat.Common.SumType
        Fiat.Narcissus.Common.Specs.

Require Import
        Coq.Sets.Ensembles
        Bedrock.Word.

Section SumType.

  Context {B : Type}.
  Context {cache : Cache}.
  Context {cacheAddNat : CacheAdd cache nat}.
  Context {monoid : Monoid B}.
  Context {monoidUnit : MonoidUnit monoid bool}.

  Definition format_SumType {m}
             (types : Vector.t Type m)
             (formatrs : ilist (B := fun T => T -> CacheFormat -> B * CacheFormat) types)
             (st : SumType types)
    : CacheFormat -> B * CacheFormat :=
    ith formatrs (SumType_index types st) (SumType_proj types st).

  Definition decode_SumType {m}
             (types : Vector.t Type m)
             (decoders : ilist (B := fun T => B -> CacheDecode -> T * B * CacheDecode) types)
             (idx : Fin.t m)
             (b : B)
             (cd : CacheDecode)
    : SumType types * B * CacheDecode :=
    let z := (ith decoders idx b cd) in
    (inj_SumType types idx (fst (fst z)), snd (fst z), snd z).

  Lemma tri_proj_eq {A C D} : forall a c d (acd : A * C * D),
      a = fst (fst acd)
      -> c = snd (fst acd)
      -> d = snd acd
      -> acd = ((a, c), d).
  Proof.
    intros; subst; intuition.
  Qed.

  Theorem SumType_decode_correct {m}
          (types : Vector.t Type m)
          (formatrs : ilist (B := fun T => T -> CacheFormat -> B * CacheFormat) types)
          (decoders : ilist (B := fun T => B -> CacheDecode -> T * B * CacheDecode) types)
          (invariants : forall idx, Vector.nth types idx -> Prop)
          (formatrs_decoders_correct : forall idx,
              format_decode_correct
                monoid
                (fun st => invariants idx st)
                (ith formatrs idx)
                (ith decoders idx))
          idx
    :
    format_decode_correct monoid (fun st => SumType_index types st = idx /\ invariants _ (SumType_proj types st))
                          (format_SumType types formatrs)
                          (decode_SumType types decoders idx).
  Proof.
    revert types formatrs decoders invariants formatrs_decoders_correct.
    unfold format_decode_correct, format_SumType, decode_SumType.
    induction types.
    - inversion idx.
    - revert types IHtypes h; pattern n, idx; apply Fin.caseS;
        clear n idx; intros; destruct H0.
      + (* First element *)
        destruct types.
        * unfold SumType in data, data'.
          eapply (formatrs_decoders_correct Fin.F1); eauto.
          injection H2; intros; subst.
          apply tri_proj_eq; eauto.
        * destruct data; try discriminate.
          injection H2; intros; subst.
          repeat split; try f_equal;
          eapply (formatrs_decoders_correct Fin.F1) with
          (ext := ext)
            (ext' := snd (fst (prim_fst decoders (mappend bin ext) env')))
            (data' := fst (fst (prim_fst decoders (mappend bin ext) env'))); intuition eauto; apply tri_proj_eq; eauto.
      + (* Second element *)
        destruct types; try discriminate.
        destruct data as [s | s]; try discriminate.
        destruct data' as [s' | s']; try discriminate.
        assert (p = SumType_index (Vector.cons Type h0 n types) s) by
            (apply Fin.FS_inj in H0;
             rewrite <- H0; reflexivity).
        assert (invariants
                  (Fin.FS (SumType_index (Vector.cons Type h0 n types) s))
                  (SumType_proj (Vector.cons Type h0 n types) s)) as H3' by
            eapply H3.
        assert (ith formatrs
                    (Fin.FS (SumType_index (Vector.cons Type h0 n types) s))
                    (SumType_proj (Vector.cons Type h0 n types) s) env =
                (bin, xenv)) as H1' by apply H1; clear H1.
        assert (Equiv xenv xenv' /\ s = s' /\ ext = ext').
        eapply IHtypes; eauto.
        intros; eapply (fun idx => formatrs_decoders_correct (Fin.FS idx));
          eauto.
        eapply H5.
        split.
        symmetry; apply H4.
        apply H3'.
        eapply tri_proj_eq;
          try solve [injection H2; intros; subst; eauto].
        intuition.
        congruence.
  Qed.
End SumType.

Arguments SumType : simpl never.
