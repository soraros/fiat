Require Import
        Coq.Strings.String
        Coq.Vectors.Vector
        Coq.omega.Omega.

Require Import
        Fiat.Common.SumType
        Fiat.Common.EnumType
        Fiat.Common.BoundedLookup
        Fiat.Common.ilist
        Fiat.Computation
        Fiat.QueryStructure.Specification.Representation.Notations
        Fiat.QueryStructure.Specification.Representation.Heading
        Fiat.QueryStructure.Specification.Representation.Tuple
        Fiat.Narcissus.BinLib
        Fiat.Narcissus.Common.Specs
        Fiat.Narcissus.Common.WordFacts
        Fiat.Narcissus.Common.ComposeCheckSum
        Fiat.Narcissus.Common.ComposeIf
        Fiat.Narcissus.Common.ComposeOpt
        Fiat.Narcissus.Formats
        Fiat.Narcissus.BaseFormats
        Fiat.Narcissus.Stores.EmptyStore
        Fiat.Narcissus.Automation.Solver
        Fiat.Narcissus.Automation.AlignedAutomation.

Require Import Bedrock.Word.

Import Vectors.VectorDef.VectorNotations.
Open Scope format_scope.
Opaque pow2. (* Don't want to be evaluating this. *)
Opaque natToWord. (* Or this. *)

(* Start Example Derivation. *)
Section EthernetPacketDecoder.

  Record EthernetHeader :=
    {Destination : Vector.t (word 8) 6;
     Source : Vector.t (word 8) 6;
     EthType : EnumType ["ARP"; "IP"; "RARP"]}.

  Definition EtherTypeCodes : Vector.t (word 16) 3 :=
    [WO~0~0~0~0~1~0~0~0~0~0~0~0~0~1~1~0;
     WO~0~0~0~0~1~0~0~0~0~0~0~0~0~0~0~0;
     WO~0~0~0~0~1~0~0~0~0~0~1~1~0~1~0~1
    ].

  Variable packet_len : nat. (* The length of the ethernet packet, *)
  (* which is a parameter to the formatr and decoder. *)
  Variable packet_len_OK : lt packet_len 1501.

  Definition EthernetHeader_Format
    : FormatM EthernetHeader ByteString :=
    format_Vector format_word ◦ Destination
   ++ format_Vector format_word ◦ Source
   ++ Either
   format_nat 16 ◦ (fun _ => packet_len)
   ++ format_word ◦ (fun _ => WO~0~1~0~1~0~1~0~1)
   ++ format_word ◦ (fun _ => WO~0~1~0~1~0~1~0~1)
   ++ format_word ◦ (fun _ => WO~1~1~0~0~0~0~0~0)
   ++ format_word ◦ (fun _ => wzero 24)
   ++ format_enum EtherTypeCodes ◦ EthType
   Or format_enum EtherTypeCodes ◦ EthType.

  Definition EthernetHeader_encoder :
    CorrectAlignedEncoderFor EthernetHeader_Format.
  Proof.
    start_synthesizing_encoder.
    (decompose_aligned_encoder; eauto).
    (decompose_aligned_encoder; eauto).
    eapply CorrectAlignedEncoderEither_E; intros.
    repeat align_encoder_step.
    repeat align_encoder_step; eauto.
    repeat align_encoder_step; eauto.
    Grab Existential Variables.
    eauto.
    eauto.
  Defined.

  (* Step Two: Extract the encoder function, and have it start encoding
     at the start of the provided ByteString [v]. *)
  Definition EthernetHeader_encoder_impl r {sz} v :=
    Eval simpl in (projT1 EthernetHeader_encoder sz v 0 r tt).

  Definition ethernet_Header_OK (e : EthernetHeader) := True.

  Definition v1042_test (b : ByteString) : bool :=
    match monoid_get_word 16 b with
    | Some w => if wlt_dec w (natToWord 16 1501) then true else false
    | _ => false
    end.

  Opaque natToWord.

  Lemma v1042_OKT
    : forall (data : EthernetHeader) (bin : ByteString) (env xenv : CacheFormat) (ext : ByteString),
      ((format_nat 16 packet_len
   ThenC (fun ctx'1 : CacheFormat =>
          (format_word WO~0~1~0~1~0~1~0~1
           ThenC (fun ctx'2 : CacheFormat =>
                  (format_word WO~0~1~0~1~0~1~0~1
                   ThenC (fun ctx'3 : CacheFormat =>
                          (format_word WO~1~1~0~0~0~0~0~0
                           ThenC (fun ctx'4 : CacheFormat =>
                                  (format_word (wzero 24)
                                   ThenC (fun ctx'5 : CacheFormat =>
                                          (format_enum EtherTypeCodes (EthType data) DoneC) ctx'5)) ctx'4)) ctx'3))
                    ctx'2)) ctx'1)) env)
                                            ↝ (bin, xenv) -> v1042_test (mappend bin ext) = true.
  Proof.
    intros.
    unfold sequence_Format, compose at 1, Bind2 in H;
      computes_to_inv; destruct v; destruct v0.
        injections.
    pose proof mappend_assoc as H'''; simpl in H'''; rewrite <- H'''.
    unfold v1042_test.
    pose proof (monoid_get_encode_word' 16 (natToWord 16 packet_len)) as H''''.
    unfold format_nat, format_word in H; computes_to_inv.
    apply (f_equal fst) in H; simpl in H.
    rewrite <- H.
    simpl mappend in *.
    rewrite H''''.
    find_if_inside; eauto.
    destruct n.
    eapply natToWord_wlt; eauto; try reflexivity.
    etransitivity.
    unfold BinNat.N.lt; rewrite <- Nnat.Nat2N.inj_compare.
    eapply Compare_dec.nat_compare_lt; eassumption.
    reflexivity.
  Qed.

  Hint Resolve v1042_OKT : bin_split_hints.

  Lemma v1042_OKE
    : forall (data : EthernetHeader) (bin : ByteString) (env xenv : CacheFormat) (ext : ByteString),
      (format_enum EtherTypeCodes (EthType data) DoneC) env ↝ (bin, xenv)
      -> v1042_test (mappend bin ext) = false.
  Proof.
    intros.
    unfold compose, Bind2, format_enum, format_word in H; computes_to_inv; subst.
    pose proof (f_equal fst H'') as H'; unfold fst in H'; rewrite <- H'.
    unfold v1042_test.
    rewrite mempty_right.
    pose monoid_get_encode_word' as H'''; rewrite H'''; find_if_inside; eauto.
    revert w; clear.
    match goal with
      |- context [Vector.nth (m := ?n) ?w ?idx] => remember idx; clear
    end.
    eapply forall_Vector_P; repeat econstructor;
      unfold wlt; compute; intros; discriminate.
  Qed.

  Hint Resolve v1042_OKE : bin_split_hints.

  Lemma valid_packet_len_OK_good_Len
    : lt packet_len (pow2 16).
  Proof.
    intros.
    etransitivity; eauto.
    rewrite <- (wordToNat_natToWord_idempotent 16 1501).
    eapply wordToNat_bound.
    simpl; eapply BinNat.N.ltb_lt; reflexivity.
  Qed.

  Hint Resolve valid_packet_len_OK_good_Len : data_inv_hints.

  Definition aligned_v1042_test
        {sz : nat}
        (v : t Core.char sz)
        (idx : nat)
    : bool :=
    match nth_opt v idx, nth_opt v (S idx) with
    | Some w1, Some w2 =>
      if wlt_dec (combine w2 w1) (natToWord 16 1501) then true else false
    | _, _ => false
    end.

  Lemma aligned_v1042_test_OK {sz}
    : forall (v : t Core.char sz),
      v1042_test (build_aligned_ByteString v) =
      aligned_v1042_test v 0.
  Proof.
    destruct v.
    reflexivity.
    destruct v.
    reflexivity.
    unfold v1042_test.
    replace (monoid_get_word 16 (build_aligned_ByteString (h :: h0 :: v)))
      with
        (Some (combine h0 h)).
    reflexivity.
    replace (build_aligned_ByteString (h :: h0 :: v))
      with (mappend (build_aligned_ByteString (h :: h0 :: Vector.nil _)) (build_aligned_ByteString v)).
    rewrite <- (monoid_get_encode_word' _ (combine h0 h) (build_aligned_ByteString v)).
    f_equal.
    f_equal.
    simpl.
    unfold Core.char in *.
    shatter_word h.
    shatter_word h0.
    simpl.
    rewrite build_aligned_ByteString_cons; simpl.
    unfold ByteString_enqueue_ByteString; simpl.
    unfold ByteString_enqueue_char.
    simpl.
    repeat f_equal.
    unfold build_aligned_ByteString; simpl.
    erewrite (ByteString_enqueue_simpl x6); simpl.
    erewrite (ByteString_enqueue_simpl x5); simpl.
    erewrite (ByteString_enqueue_simpl x4); simpl.
    erewrite (ByteString_enqueue_simpl x3); simpl.
    erewrite (ByteString_enqueue_simpl x2); simpl.
    erewrite (ByteString_enqueue_simpl x1); simpl.
    erewrite (ByteString_enqueue_simpl x0); simpl.
    unfold ByteString_enqueue; simpl.
    f_equal.
    eapply Core.le_uniqueness_proof.
    simpl.
    rewrite <- build_aligned_ByteString_append.
    reflexivity.
    Grab Existential Variables.
    simpl; omega.
    simpl; omega.
    simpl; omega.
    simpl; omega.
    simpl; omega.
    simpl; omega.
    simpl; omega.
  Qed.

  Definition EthernetHeader_decoder
    : CorrectAlignedDecoderFor ethernet_Header_OK EthernetHeader_Format.
  Proof.
  (* We have to use an extra lemma at the start, because of the 'exotic'
     IP Checksum. *)
  (* Once that's done, the normal automation works just fine :) *)
  start_synthesizing_decoder.
  match goal with
  | |- CorrectDecoder ?monoid _ _ _ _ _ => normalize_compose monoid
  end.
  repeat decode_step ltac:(idtac).
  cbv beta; synthesize_cache_invariant.
  (* Perform algebraic simplification of the decoder implementation. *)
  cbv beta; unfold decode_nat; optimize_decoder_impl.
  cbv beta; align_decoders.
  eapply @AlignedDecode_ifb_dep.
  intros; rewrite aligned_v1042_test_OK; higher_order_reflexivity.
  simpl; intros; pattern sz, v; eapply Vector.caseS; reflexivity.
  repeat align_decoders_step.
  repeat align_decoders_step.
Defined.

(* Step Four: Extract the decoder function, and have /it/ start decoding
   at the start of the provided ByteString [v]. *)

Definition Ethernet_decoder_impl {sz} v :=
  Eval simpl in (projT1 EthernetHeader_decoder sz v 0 ()).

End EthernetPacketDecoder.

Print Ethernet_decoder_impl.
