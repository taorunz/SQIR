Require Export UnitarySem.
Require Import Dirac.

Local Open Scope ucom_scope.
Local Close Scope C_scope.
Local Close Scope R_scope.

(** Reasoning about classical states. **)

(* General facts about (nat -> A) functions.

   TODO #1: These lemmas are probably already defined in Coq somewhere.
   TODO #2: For efficiency, instead of using functions indexed by natural
            numbers, we should use vectors/arrays. *)

(* Update the value at one index of a boolean function. *)
Definition update {A} (f : nat -> A) (i : nat) (x : A) :=
  fun j => if j =? i then x else f j.

Lemma update_index_eq : forall {A} (f : nat -> A) i b, (update f i b) i = b.
Proof.
  intros. 
  unfold update.
  replace (i =? i) with true by (symmetry; apply Nat.eqb_eq; reflexivity).
  reflexivity.
Qed.

Lemma update_index_neq : forall {A} (f : nat -> A) i j b, i <> j -> (update f i b) j = f j.
Proof.
  intros. 
  unfold update.
  bdestruct (j =? i); try easy. 
  contradict H0; lia.
Qed.

Lemma update_same : forall {A} (f : nat -> A) i b,
  b = f i -> update f i b = f.
Proof.
  intros.
  apply functional_extensionality.
  intros.
  unfold update.
  bdestruct (x =? i); subst; reflexivity.
Qed.

Lemma update_twice_eq : forall {A} (f : nat -> A) i b b',
  update (update f i b) i b' = update f i b'.
Proof.
  intros.
  apply functional_extensionality.
  intros.
  unfold update.
  bdestruct (x =? i); subst; reflexivity.
Qed.  

Lemma update_twice_neq : forall {A} (f : nat -> A) i j b b',
  i <> j -> update (update f i b) j b' = update (update f j b') i b.
Proof.
  intros.
  apply functional_extensionality.
  intros.
  unfold update.
  bdestruct (x =? i); bdestruct (x =? j); subst; 
  try (contradict H; reflexivity); reflexivity.
Qed.

(* Convert a boolean function to a vector; examples: 
     f_to_vec 0 3 f --> ((I 1 ⊗ ∣ f 0 ⟩) ⊗ ∣ f 1 ⟩) ⊗ | f 2 ⟩ 
     f_to_vec 2 2 f -->  (I 1 ⊗ ∣ f 2 ⟩) ⊗ ∣ f 3 ⟩ 
*)
Local Coercion Nat.b2n : bool >-> nat.
Fixpoint f_to_vec (base n : nat) (f : nat -> bool) : Vector (2^n) :=
  match n with 
  | 0 => I 1
  | S n' =>  (f_to_vec base n' f) ⊗ ∣ f (base + n')%nat ⟩
  end.

Lemma f_to_vec_WF : forall (base n : nat) (f : nat -> bool),
  WF_Matrix (f_to_vec base n f).
Proof.
  intros.
  induction n; simpl; try auto with wf_db.
  apply WF_kron; try lia; try assumption.
  destruct (f (base + n)%nat); auto with wf_db.
Qed.
Hint Resolve f_to_vec_WF : wf_db.

(* Lemmas about basis vectors *)

Definition basis_vector (n k : nat) : Vector n :=
  fun i j => if (i =? k) && (j =? 0) then C1 else C0.

Lemma basis_vector_WF : forall n i, (i < n)%nat -> WF_Matrix (basis_vector n i).
Proof.
  unfold basis_vector, WF_Matrix.
  intros.
  bdestruct (n <=? x)%nat; bdestruct (1 <=? y)%nat; try lia.
  bdestructΩ (x =? i)%nat. reflexivity.
  bdestructΩ (x =? i)%nat. reflexivity.
  bdestructΩ (y =? 0)%nat. rewrite andb_false_r. reflexivity.
Qed.
Hint Resolve basis_vector_WF : wf_db.

Lemma matrix_times_basis_eq : forall m n (A : Matrix m n) i j,
  WF_Matrix A ->
  (A × basis_vector n j) i 0 = A i j.
Proof.
  intros m n A i j WFA.
  unfold basis_vector.
  unfold Mmult.
  bdestruct (j <? n).
  2:{ rewrite Csum_0. rewrite WFA; auto. 
      intros j'. bdestruct (j' =? j); subst; simpl; try lca.
      rewrite WFA. lca. auto.  }
  erewrite Csum_unique.
  reflexivity.
  exists j.
  repeat split; trivial.
  rewrite <- 2 beq_nat_refl; simpl; lca.
  intros j' Hj.
  rewrite eqb_neq; auto. simpl. lca.
Qed.  
  
Lemma equal_on_basis_vectors_implies_equal : forall m n (A B : Matrix m n),
  WF_Matrix A -> 
  WF_Matrix B ->
  (forall k, k < n -> A × (basis_vector n k) = B × (basis_vector n k)) ->
  A = B.
Proof.
  intros m n A B WFA WFB H.
  prep_matrix_equality.
  bdestruct (y <? n). 2: rewrite WFA, WFB; auto.
  rewrite <- matrix_times_basis_eq; trivial.
  rewrite H; trivial.
  rewrite matrix_times_basis_eq; easy.
Qed.

(* takes [1;1;0;0] to 3, [0;0;1;0] to 4 *)
Fixpoint binlist_to_nat (l : list bool) : nat :=
  match l with
  | [] => 0
  | b :: l' => b + 2 * binlist_to_nat l'
  end.

Fixpoint funbool_to_list (len : nat) (f : nat -> bool) :=
  match len with
  | O => []
  | S len' => f len' :: funbool_to_list len' f
  end.

Definition funbool_to_nat (len : nat) (f : nat -> bool) :=
  binlist_to_nat (funbool_to_list len f).

Lemma funbool_to_nat_bound : forall n f, (funbool_to_nat n f < 2 ^ n)%nat.
Proof.
  intros n f.
  unfold funbool_to_nat.
  induction n; simpl. lia.
  destruct (f n); simpl; lia.
Qed.

Lemma basis_f_to_vec : forall n f,
  f_to_vec 0 n f = basis_vector (2^n) (funbool_to_nat n f).
Proof.
  intros.
  induction n.
  - unfold funbool_to_nat; simpl.
    unfold basis_vector.
    unfold I.
    prep_matrix_equality.
    bdestruct (x =? 0); bdestruct (x =? y); subst; simpl; trivial.
    rewrite eqb_neq; auto.
    bdestructΩ (y <? 1); easy.
  - simpl.
    rewrite IHn.
    unfold funbool_to_nat; simpl.
    unfold basis_vector.
    prep_matrix_equality. unfold kron. 
    rewrite Nat.div_1_r.
    bdestruct (y =? 0).
    2: rewrite 2 andb_false_r; lca.
    rewrite 2 andb_true_r.
    rewrite Nat.mod_1_r, Nat.add_0_r.
    remember (binlist_to_nat (funbool_to_list n f)) as z.
    destruct (f n).
    + specialize (Nat.div_mod x 2) as DM.
      rewrite <- Nat.bit0_mod in *.
      destruct (Nat.testbit x 0); bdestruct (x / 2 =? z);
        simpl in *; bdestruct (x =? S (z + z)); try lia; try lca.
    + specialize (Nat.div_mod x 2) as DM.
      rewrite <- Nat.bit0_mod in *.
      destruct (Nat.testbit x 0); bdestruct (x / 2 =? z);
        simpl in *; bdestruct (x =? (z + z)); try lia; try lca.
Qed.

Fixpoint incr_bin (l : list bool) :=
  match l with
  | []        => [true]
  | false :: t => true :: t
  | true :: t  => false :: (incr_bin t)
  end.

Fixpoint nat_to_binlist' n :=
  match n with
  | O    => []
  | S n' => incr_bin (nat_to_binlist' n')
  end.
Definition nat_to_binlist len n := 
  let l := nat_to_binlist' n in
  l ++ (repeat false (len - length l)).

Fixpoint list_to_funbool len (l : list bool) : nat -> bool :=
  match l with
  | []    => fun _ => false
  | h :: t => update (list_to_funbool (len - 1)%nat t) (len - 1) h
  end.

Definition nat_to_funbool len n : nat -> bool :=
  list_to_funbool len (nat_to_binlist len n).

Lemma binlist_to_nat_append : forall l1 l2,
  binlist_to_nat (l1 ++ l2) = 
    (binlist_to_nat l1 +  2 ^ (length l1) * binlist_to_nat l2)%nat.
Proof. intros l1 l2. induction l1; simpl; lia. Qed.

Lemma binlist_to_nat_false : forall n, binlist_to_nat (repeat false n) = O.
Proof. induction n; simpl; lia. Qed.

Lemma nat_to_binlist_eq_nat_to_binlist' : forall len n, 
  binlist_to_nat (nat_to_binlist len n) = binlist_to_nat (nat_to_binlist' n).
Proof.
  intros len n.
  unfold nat_to_binlist. 
  rewrite binlist_to_nat_append.
  rewrite binlist_to_nat_false. 
  lia.
Qed.

Lemma nat_to_binlist_inverse : forall len n,
  binlist_to_nat (nat_to_binlist len n) = n.
Proof.
  intros len n.
  rewrite nat_to_binlist_eq_nat_to_binlist'.
  induction n; simpl.
  reflexivity.
  assert (H : forall l, binlist_to_nat (incr_bin l) = S (binlist_to_nat l)).
  { clear.
    induction l; simpl.
    reflexivity.
    destruct a; simpl; try reflexivity.
    rewrite IHl. lia. }
  rewrite H, IHn.
  reflexivity.
Qed.

Lemma nat_to_binlist_length : forall len n,
  (n < 2 ^ len)%nat -> length (nat_to_binlist len n) = len.
Proof.
  intros len n Hlen.
  unfold nat_to_binlist.
  rewrite app_length, repeat_length. 
  bdestruct (n =? 0); subst; simpl. lia.
  assert (length (nat_to_binlist' n) <= len)%nat.
  { (* Definitely true with the current assumptions (n > 0 /\ n < 2 ^ len), 
       but I'm stuck on the proof -KH *)
     admit. }
  lia.
Admitted.


Lemma funbool_to_list_update_oob : forall f dim b n, (dim <= n)%nat ->
  funbool_to_list dim (update f n b) = funbool_to_list dim f.
Proof.
  intros.
  induction dim; trivial.
  simpl.
  rewrite IHdim by lia.
  unfold update.
  bdestruct (dim =? n); try lia.
  reflexivity.
Qed.

Lemma list_to_funbool_inverse : forall len l,
  length l = len ->
  funbool_to_list len (list_to_funbool len l) = l.
Proof.
  intros len l.
  generalize dependent len.
  induction l; intros len Hlen.
  simpl in Hlen; rewrite <- Hlen.
  simpl. reflexivity.
  simpl in Hlen; rewrite <- Hlen.
  simpl.
  replace (length l - 0)%nat with (length l) by lia.
  rewrite update_index_eq.
  rewrite funbool_to_list_update_oob by lia.
  rewrite IHl; reflexivity.
Qed.

Lemma nat_to_funbool_inverse : forall len n, 
  (n < 2 ^ len)%nat -> funbool_to_nat len (nat_to_funbool len n) = n.
Proof.
  intros.
  unfold nat_to_funbool, funbool_to_nat.
  rewrite list_to_funbool_inverse.
  apply nat_to_binlist_inverse.
  apply nat_to_binlist_length.
  assumption.
Qed.

(* Another way of converting between basis_vector and f_to_vec *)
Lemma basis_f_to_vec_alt : forall len n, (n < 2 ^ len)%nat -> 
  basis_vector (2 ^ len) n = f_to_vec 0 len (nat_to_funbool len n).
Proof.
  intros.
  rewrite basis_f_to_vec.
  rewrite nat_to_funbool_inverse; auto.
Qed.

Lemma equal_on_basis_states_implies_equal : forall {dim} (A B : Square (2 ^ dim)),
  WF_Matrix A -> 
  WF_Matrix B ->
  (forall f, A × (f_to_vec 0 dim f) = B × (f_to_vec 0 dim f)) ->
  A = B.
Proof.
  intros dim A B WFA WFB H.
  apply equal_on_basis_vectors_implies_equal; trivial.
  intros k Lk.
  rewrite basis_f_to_vec_alt; auto.
Qed.

Lemma f_to_vec_update : forall (base n : nat) (f : nat -> bool) (i : nat) (b : bool),
  (i < base \/ base + n <= i)%nat ->
  f_to_vec base n (update f i b) = f_to_vec base n f.
Proof.
  intros.
  destruct H.
  - induction n; simpl; try reflexivity.
    unfold update.
    bdestruct (base + n =? i).
    contradict H0. lia.
    rewrite <- IHn.
    reflexivity.
  - induction n; simpl; try reflexivity.
    unfold update.
    bdestruct (base + n =? i).
    contradict H0. lia.
    rewrite <- IHn.
    reflexivity. lia.
Qed.

Lemma f_to_vec_split : forall (base n i : nat) (f : nat -> bool),
  i < n ->
  f_to_vec base n f = (f_to_vec base i f) ⊗ ∣ f (base + i)%nat ⟩ ⊗ (f_to_vec (base + i + 1) (n - 1 - i) f).
Proof.
  intros.
  induction n.
  - contradict H. lia.
  - bdestruct (i =? n).
    + subst.
      replace (S n - 1 - n)%nat with O by lia.
      simpl. Msimpl.
      reflexivity.
    + assert (i < n)%nat by lia.
      specialize (IHn H1).
      replace (S n - 1 - i)%nat with (S (n - 1 - i))%nat by lia.
      simpl.
      rewrite IHn.
      replace (base + i + 1 + (n - 1 - i))%nat with (base + n)%nat by lia.
      restore_dims; repeat rewrite kron_assoc. 
      reflexivity.
Qed.

Lemma f_to_vec_X : forall (n i : nat) (f : nat -> bool),
  i < n ->
  (uc_eval (X i)) × (f_to_vec 0 n f) 
      = f_to_vec 0 n (update f i (¬ (f i))).
Proof.
  intros.
  autorewrite with eval_db.
  rewrite (f_to_vec_split 0 n i f H). 
  simpl; replace (n - 1 - i) with (n - (i + 1)) by lia.
  repad. 
  Msimpl.
  rewrite (f_to_vec_split 0 (i + 1 + x) i); try lia.
  repeat rewrite (f_to_vec_update _ _ _ i (¬ (f i))).
  2: left; lia.
  2: right; lia.
  destruct (f i); simpl; rewrite update_index_eq;
  simpl; autorewrite with ket_db;
  replace (i + 1 + x - 1 - i) with x by lia;
  reflexivity.
Qed.

Lemma f_to_vec_CNOT : forall (n i j : nat) (f : nat -> bool),
  i < n ->
  j < n ->
  i <> j ->
  (uc_eval (SQIR.CNOT i j)) × (f_to_vec 0 n f) 
      = f_to_vec 0 n (update f j (f j ⊕ f i)).
Proof.
  intros.
  autorewrite with eval_db.
  repad.
  - repeat rewrite (f_to_vec_split 0 (i + (1 + d + 1) + x) i); try lia.
    rewrite f_to_vec_update.
    2: right; lia.
    rewrite update_index_neq; try lia.
    repeat rewrite (f_to_vec_split (0 + i + 1) (i + (1 + d + 1) + x - 1 - i) d); try lia.
    repeat rewrite f_to_vec_update.
    2: left; lia.
    2: right; lia.
    simpl; rewrite update_index_eq.
    replace (i + S (d + 1) + x - 1 - i - 1 - d) with x by lia.
    distribute_plus.  
    restore_dims.
    repeat rewrite <- kron_assoc.
    destruct (f i); destruct (f (i + 1 + d)); simpl; Msimpl.
    all: repeat rewrite Mmult_assoc. 
    all: replace ((∣1⟩)† × ∣ 1 ⟩) with (I 1) by solve_matrix. 
    all: replace ((∣0⟩)† × ∣ 0 ⟩) with (I 1) by solve_matrix.  
    all: replace ((∣1⟩)† × ∣ 0 ⟩) with (@Zero 1 1) by solve_matrix.
    all: replace ((∣0⟩)† × ∣ 1 ⟩) with (@Zero 1 1) by solve_matrix.
    all: Msimpl_light; try reflexivity.
    rewrite X1_spec; reflexivity.
    rewrite X0_spec; reflexivity.
  - repeat rewrite (f_to_vec_split 0 (j + (1 + d + 1) + x0) j); try lia.
    rewrite f_to_vec_update.
    2: right; lia.
    replace (0 + j) with j by reflexivity.
    rewrite update_index_eq.
    repeat rewrite (f_to_vec_split (j + 1) (j + (1 + d + 1) + x0 - 1 - j) d); try lia.
    repeat rewrite f_to_vec_update.
    2, 3: left; lia.
    rewrite update_index_neq; try lia.
    replace (j + (1 + d + 1) + x0 - 1 - j - 1 - d) with x0 by lia.
    distribute_plus.  
    restore_dims.
    repeat rewrite <- kron_assoc.
    destruct (f j); destruct (f (j + 1 + d)); simpl; Msimpl.
    all: repeat rewrite Mmult_assoc. 
    all: replace ((∣1⟩)† × ∣ 1 ⟩) with (I 1) by solve_matrix. 
    all: replace ((∣0⟩)† × ∣ 0 ⟩) with (I 1) by solve_matrix.  
    all: replace ((∣1⟩)† × ∣ 0 ⟩) with (@Zero 1 1) by solve_matrix.
    all: replace ((∣0⟩)† × ∣ 1 ⟩) with (@Zero 1 1) by solve_matrix.
    all: Msimpl_light; try reflexivity.
    rewrite X1_spec; reflexivity.
    rewrite X0_spec; reflexivity.
Qed.    

Local Transparent SWAP.
Lemma f_to_vec_SWAP : forall (n i j : nat) (f : nat -> bool),
  i < n -> j < n -> i <> j ->
  uc_eval (SWAP i j) × (f_to_vec 0 n f) = f_to_vec 0 n (update (update f j (f i)) i (f j)).
Proof.
  intros n i j f ? ? ?.
  unfold SWAP; simpl.
  repeat rewrite Mmult_assoc.
  rewrite 3 f_to_vec_CNOT by auto.
  repeat rewrite update_index_eq.
  repeat rewrite update_index_neq by lia.
  repeat rewrite update_index_eq.
  replace ((f j ⊕ f i) ⊕ (f i ⊕ (f j ⊕ f i))) with (f i).
  replace (f i ⊕ (f j ⊕ f i)) with (f j).
  rewrite update_twice_neq by auto.
  rewrite update_twice_eq.
  reflexivity.
  all: destruct (f i); destruct (f j); auto.
Qed.
Local Opaque SWAP.
                                  
Definition b2R (b : bool) : R := if b then 1%R else 0%R.
Local Coercion b2R : bool >-> R.

Lemma phase_shift_on_basis_state : forall (θ : R) (b : bool),
  phase_shift θ × ∣ b ⟩ = (Cexp (b * θ)) .* ∣ b ⟩.
Proof.
  intros.
  destruct b; solve_matrix; autorewrite with R_db.
  reflexivity.
  rewrite Cexp_0; reflexivity.
Qed.

Lemma f_to_vec_Rz : forall (n i : nat) (θ : R) (f : nat -> bool),
  (i < n)%nat ->
  (uc_eval (SQIR.Rz θ i)) × (f_to_vec 0 n f) 
      = (Cexp ((f i) * θ)) .* f_to_vec 0 n f.
Proof.
  intros.
  autorewrite with eval_db.
  rewrite (f_to_vec_split 0 n i f H). 
  simpl; replace (n - 1 - i)%nat with (n - (i + 1))%nat by lia.
  repad. 
  Msimpl.
  rewrite phase_shift_on_basis_state.
  rewrite Mscale_kron_dist_r.
  rewrite Mscale_kron_dist_l.
  reflexivity.
Qed.

Local Open Scope C_scope.
Local Open Scope R_scope.
Lemma hadamard_on_basis_state : forall (b : bool),
  hadamard × ∣ b ⟩ = /√2 .* (∣ 0 ⟩ .+ (Cexp (b * PI)) .* ∣ 1 ⟩).
Proof.
  intros.
  destruct b; solve_matrix; autorewrite with R_db Cexp_db; lca.
Qed.

Lemma f_to_vec_H : forall (n i : nat) (f : nat -> bool),
  (i < n)%nat ->
  (uc_eval (SQIR.H i)) × (f_to_vec 0 n f) 
      = /√2 .* ((f_to_vec 0 n (update f i false)) .+ (Cexp ((f i) * PI)) .* f_to_vec 0 n (update f i true)).
Proof.
  intros.
  autorewrite with eval_db.
  rewrite (f_to_vec_split 0 n i f H). 
  simpl; replace (n - 1 - i)%nat with (n - (i + 1))%nat by lia.
  repad. 
  Msimpl.
  rewrite hadamard_on_basis_state.
  rewrite Mscale_kron_dist_r, Mscale_kron_dist_l.
  rewrite kron_plus_distr_l, kron_plus_distr_r.
  rewrite Mscale_kron_dist_r, Mscale_kron_dist_l.
  rewrite 2 (f_to_vec_split 0 (i + 1 + x) i _) by lia.
  replace (i + 1 + x - 1 - i)%nat with x by lia.
  simpl.
  rewrite 2 update_index_eq.
  repeat rewrite f_to_vec_update.
  reflexivity.
  all: try (left; lia); right; lia.
Qed.
Local Close Scope C_scope.
Local Close Scope R_scope.

(* Projector onto the space where qubit q is in classical state b. *)
Definition proj q dim (b : bool) := @pad 1 q dim (∣ b ⟩ × (∣ b ⟩)†).

Lemma WF_proj : forall q dim b, WF_Matrix (proj q dim b).
Proof. intros. unfold proj, pad. bdestruct_all; destruct b; auto with wf_db. Qed.
Hint Resolve WF_proj : wf_db.

Lemma f_to_vec_proj_1 : forall f q n b,
  q < n -> f q = b ->
  proj q n b × (f_to_vec 0 n f) = f_to_vec 0 n f.
Proof.
  intros f q n b ? ?.
  rewrite (f_to_vec_split 0 n q) by lia. 
  replace (n - 1 - q)%nat with (n - (q + 1))%nat by lia.
  unfold proj, pad.
  gridify. 
  do 2 (apply f_equal2; try reflexivity). 
  destruct (f q); solve_matrix.
Qed.

Lemma f_to_vec_proj_2 : forall f q n b,
  q < n -> f q <> b ->
  proj q n b × (f_to_vec 0 n f) = Zero.
Proof.
  intros f q n b ? H.
  rewrite (f_to_vec_split 0 n q) by lia. 
  replace (n - 1 - q)%nat with (n - (q + 1))%nat by lia.
  unfold proj, pad.
  gridify. 
  destruct (f q); destruct b; try easy; lma.
Qed.

Lemma proj_commutes_1q_gate : forall dim u q n b,
  q <> n ->
  proj q dim b × ueval_r dim n u = ueval_r dim n u × proj q dim b. 
Proof.
  intros dim u q n b neq.
  dependent destruction u; simpl.
  unfold proj, pad.
  gridify; trivial.
  all: destruct b; auto with wf_db.
Qed.

Lemma proj_commutes_2q_gate : forall dim q n1 n2 b,
  q <> n1 -> q <> n2 ->
  proj q dim b × ueval_cnot dim n1 n2 = ueval_cnot dim n1 n2 × proj q dim b. 
Proof.
  intros dim q n1 n2 b neq1 neq2.
  unfold proj, ueval_cnot, pad.
  gridify; trivial.
  all: destruct b; auto with wf_db.
Qed.

Lemma proj_commutes : forall dim q1 q2 b1 b2,
  proj q1 dim b1 × proj q2 dim b2 = proj q2 dim b2 × proj q1 dim b1.
Proof.
  intros dim q1 q2 b1 b2.
  unfold proj, pad.
  gridify; trivial.
  all: destruct b1; destruct b2; auto with wf_db.
  all: Qsimpl; reflexivity.
Qed.

Lemma proj_twice_eq : forall dim q b,
  proj q dim b × proj q dim b = proj q dim b.
Proof.
  intros dim q b.
  unfold proj, pad.
  gridify.
  destruct b; Qsimpl; reflexivity.
Qed.

Lemma proj_twice_neq : forall dim q b1 b2,
  b1 <> b2 -> proj q dim b1 × proj q dim b2 = Zero.
Proof.
  intros dim q b1 b2 neq.
  unfold proj, pad.
  gridify.
  destruct b1; destruct b2; try contradiction; Qsimpl; reflexivity.
Qed.

Lemma proj_X : forall dim f q n,
  proj q dim (update f n (¬ (f n)) q) × uc_eval (SQIR.X n) = uc_eval (SQIR.X n) × proj q dim (f q).
Proof.
  intros dim f q n.
  bdestruct (q =? n).
  subst. rewrite update_index_eq.
  unfold proj.
  autorewrite with eval_db.
  gridify.
  destruct (f n); Qsimpl; reflexivity.    
  rewrite update_index_neq; [| lia].
  replace (@uc_eval dim (SQIR.X n)) with (ueval_r dim n (U_R PI 0 PI)) by reflexivity.
  rewrite proj_commutes_1q_gate; [| lia].
  reflexivity.
Qed.

Lemma phase_shift_on_basis_state_adj : forall (θ : R) (b : bool),
  (∣ b ⟩)† × phase_shift θ = (Cexp (b * θ)) .* (∣ b ⟩)†.
Proof.
  intros.
  destruct b; solve_matrix; autorewrite with R_db.
  reflexivity.
  rewrite Cexp_0; reflexivity.
Qed.

Lemma proj_Rz_comm : forall dim q n b k,
  proj q dim b × uc_eval (SQIR.Rz k n) = uc_eval (SQIR.Rz k n) × proj q dim b. 
Proof.
  intros dim q n b k.
  unfold proj.
  autorewrite with eval_db.
  gridify.
  all: destruct b; auto with wf_db.
  all: repeat rewrite <- Mmult_assoc; rewrite phase_shift_on_basis_state.
  all: repeat rewrite Mmult_assoc; rewrite phase_shift_on_basis_state_adj. 
  all: rewrite Mscale_mult_dist_r, Mscale_mult_dist_l; reflexivity.
Qed.

Lemma proj_Rz : forall dim q b θ,
  uc_eval (SQIR.Rz θ q) × proj q dim b = Cexp (b * θ) .* proj q dim b. 
Proof.
  intros dim q b θ.
  unfold proj.
  autorewrite with eval_db.
  gridify.
  destruct b.
  all: repeat rewrite <- Mmult_assoc; rewrite phase_shift_on_basis_state.
  all: rewrite Mscale_mult_dist_l, Mscale_kron_dist_r, Mscale_kron_dist_l; 
       reflexivity.
Qed.

Lemma proj_CNOT_control : forall dim q m n b,
  (q <> n \/ m = n) ->
  proj q dim b × uc_eval (SQIR.CNOT m n) = uc_eval (SQIR.CNOT m n) × proj q dim b.
Proof.
  intros dim q m n b H.
  destruct H.
  bdestruct (m =? n).
  (* badly typed case *)
  1,3: subst; replace (uc_eval (SQIR.CNOT n n)) with (@Zero (2 ^ dim) (2 ^ dim));
       Msimpl_light; try reflexivity.
  1,2: autorewrite with eval_db; bdestructΩ (n <? n); reflexivity.
  bdestruct (q =? m).
  (* q = control *)
  subst. unfold proj.
  autorewrite with eval_db.
  gridify.
  destruct b; Qsimpl; reflexivity.
  destruct b; Qsimpl; reflexivity.
  (* disjoint qubits *)
  bdestructΩ (q =? n).
  apply proj_commutes_2q_gate; assumption.
Qed.

Lemma proj_CNOT_target : forall dim f q n,
  proj q dim ((f q) ⊕ (f n)) × proj n dim (f n) × uc_eval (SQIR.CNOT n q) = proj n dim (f n) × uc_eval (SQIR.CNOT n q) × proj q dim (f q).
Proof.
  intros dim f q n.
  unfold proj.
  autorewrite with eval_db.
  gridify. (* slow! *)
  all: try (destruct (f n); destruct (f (n + 1 + d)%nat));        
       try (destruct (f q); destruct (f (q + 1 + d)%nat));   
       auto with wf_db.
  all: simpl; Qsimpl; reflexivity.
Qed.

(* We can use 'proj' to state that qubit q is in classical state b. *)
Definition classical {dim} q b (ψ : Vector (2 ^ dim)) := proj q dim b × ψ = ψ.

Lemma f_to_vec_classical : forall n q f,
  (q < n)%nat -> classical q (f q) (f_to_vec 0 n f).
Proof.
  intros n q f Hq.
  unfold classical, proj.
  induction n; try lia.
  unfold pad.
  replace (q + 1)%nat with (S q) by lia. 
  bdestructΩ (S q <=? S n); clear H.
  bdestruct (q =? n).
  - subst. replace (n - n)%nat with O by lia.
    simpl. Msimpl_light.
    restore_dims.
    rewrite kron_mixed_product.
    Msimpl_light; apply f_equal2; auto.
    destruct (f n); solve_matrix.
  - remember (n - q - 1)%nat as x.
    replace (n - q)%nat with (x + 1)%nat by lia.
    replace n with (q + 1 + x)%nat by lia.
    replace (2 ^ (x + 1))%nat with (2 ^ x * 2)%nat by unify_pows_two.
    rewrite <- id_kron.
    rewrite <- kron_assoc.
    replace (2 ^ (q + 1 + x) + (2 ^ (q + 1 + x) + 0))%nat with (2 ^ (q + 1 + x) * 2)%nat by lia.
    repeat rewrite Nat.pow_add_r.
    replace 1%nat with (1 * 1)%nat by lia. 
    rewrite kron_mixed_product; simpl.
    replace (q + 1 + x)%nat with n by lia.
    subst.
    Msimpl_light.
    2: destruct (f n); auto with wf_db.
    rewrite <- IHn at 2; try lia.
    unfold pad. 
    bdestructΩ (q + 1 <=? n); clear H0.
    replace (n - (q + 1))%nat with (n - q - 1)%nat by lia.
    restore_dims. reflexivity.
Qed.