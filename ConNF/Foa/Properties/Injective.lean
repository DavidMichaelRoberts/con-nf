import ConNF.Foa.Properties.ConstrainedAction

open Equiv Function Quiver Set Sum WithBot

open scoped Classical Pointwise

universe u

namespace ConNF

namespace StructApprox

variable [Params.{u}] {α : Λ} [PositionData] [Phase2Assumptions α] {β : Iic α}
  [FreedomOfActionHypothesis β] {π : StructApprox β}

theorem atom_injective_extends {c d : SupportCondition β} (hcd : (ihsAction π c d).Lawful)
    {a b : Atom} {A : ExtendedIndex β} (hac : (inl a, A) ∈ reflTransConstrained c d)
    (hbc : (inl b, A) ∈ reflTransConstrained c d)
    (h : π.completeAtomMap A a = π.completeAtomMap A b) : a = b :=
  by
  by_cases ha : a ∈ (π A).atomPerm.domain <;> by_cases hb : b ∈ (π A).atomPerm.domain
  · rw [completeAtomMap_eq_of_mem_domain ha, completeAtomMap_eq_of_mem_domain hb] at h
    exact (π A).atomPerm.injOn ha hb h
  · rw [completeAtomMap_eq_of_mem_domain ha, completeAtomMap_eq_of_not_mem_domain hb] at h
    cases
      (π A).not_mem_domain_of_mem_largestSublitter (Subtype.coe_eq_iff.mp h.symm).choose
        ((π A).atomPerm.map_domain ha)
  · rw [completeAtomMap_eq_of_not_mem_domain ha, completeAtomMap_eq_of_mem_domain hb] at h
    cases
      (π A).not_mem_domain_of_mem_largestSublitter (Subtype.coe_eq_iff.mp h).choose
        ((π A).atomPerm.map_domain hb)
  · rw [completeAtomMap_eq_of_not_mem_domain ha, completeAtomMap_eq_of_not_mem_domain hb] at h
    have h₁ := (Subtype.coe_eq_iff.mp h).choose.1
    have h₂ :=
      (((π A).largestSublitter b.1).equiv ((π A).largestSublitter (π.completeLitterMap A b.1))
            ⟨b, (π A).mem_largestSublitter_of_not_mem_domain b hb⟩).prop.1
    have := (hcd A).litterMap_injective (fst_transConstrained hac) (fst_transConstrained hbc) ?_
    · have := eq_of_sublitter_bijection_apply_eq h this (by rw [this])
      exact this
    · refine' NearLitter.inter_nonempty_of_fst_eq_fst _
      simp only [ihsAction_litterMap, completeNearLitterMap_fst_eq]
      exact eq_of_mem_litterSet_of_mem_litterSet h₁ h₂

def InOut (π : NearLitterPerm) (a : Atom) (L : Litter) : Prop :=
  Xor' (a.1 = L) ((π • a).1 = π • L)

theorem inOut_def {π : NearLitterPerm} {a : Atom} {L : Litter} :
    InOut π a L ↔ Xor' (a.1 = L) ((π • a).1 = π • L) :=
  Iff.rfl

structure _root_.ConNF.NearLitterPerm.Biexact (π π' : NearLitterPerm) (atoms : Set Atom)
    (litters : Set Litter) : Prop where
  smul_eq_smul_atom : ∀ a ∈ atoms, π • a = π' • a
  smul_eq_smul_litter : ∀ L ∈ litters, π • L = π' • L
  left_exact : ∀ L ∈ litters, ∀ a, InOut π a L → π • a = π' • a
  right_exact : ∀ L ∈ litters, ∀ a, InOut π' a L → π • a = π' • a

@[simp]
theorem xor'_elim_left {a b : Prop} (h : a) : Xor' a b ↔ ¬b := by unfold Xor'; tauto

@[simp]
theorem xor'_elim_right {a b : Prop} (h : b) : Xor' a b ↔ ¬a := by unfold Xor'; tauto

@[simp]
theorem xor'_elim_not_left {a b : Prop} (h : ¬a) : Xor' a b ↔ b := by unfold Xor'; tauto

@[simp]
theorem xor'_elim_not_right {a b : Prop} (h : ¬b) : Xor' a b ↔ a := by unfold Xor'; tauto

theorem _root_.ConNF.NearLitterPerm.Biexact.atoms {π π' : NearLitterPerm} (s : Set Atom)
    (hs : ∀ a ∈ s, π • a = π' • a) : NearLitterPerm.Biexact π π' s ∅ :=
  ⟨hs, fun _ => False.elim, fun _ => False.elim, fun _ => False.elim⟩

theorem _root_.ConNF.NearLitterPerm.Biexact.litter {π π' : NearLitterPerm} (L : Litter)
    (hL : π • L = π' • L) (hL₁ : ∀ a, InOut π a L → π • a = π' • a)
    (hL₂ : ∀ a, InOut π' a L → π • a = π' • a) : NearLitterPerm.Biexact π π' ∅ {L} :=
  ⟨fun a ha => ha.elim, fun L' hL' => by cases hL'; exact hL, fun L' hL' => by
    cases hL'; exact hL₁, fun L' hL' => by cases hL'; exact hL₂⟩

theorem _root_.ConNF.NearLitterPerm.Biexact.symm {π π' : NearLitterPerm} {atoms : Set Atom}
    {litters : Set Litter} (h : NearLitterPerm.Biexact π π' atoms litters) :
    NearLitterPerm.Biexact π' π atoms litters :=
  ⟨fun a ha => (h.smul_eq_smul_atom a ha).symm, fun L hL => (h.smul_eq_smul_litter L hL).symm,
    fun L hL a ha => (h.right_exact L hL a ha).symm, fun L hL a ha => (h.left_exact L hL a ha).symm⟩

theorem _root_.ConNF.NearLitterPerm.Biexact.union {π π' : NearLitterPerm} {s₁ s₂ : Set Atom}
    {t₁ t₂ : Set Litter} (h₁ : NearLitterPerm.Biexact π π' s₁ t₁)
    (h₂ : NearLitterPerm.Biexact π π' s₂ t₂) : NearLitterPerm.Biexact π π' (s₁ ∪ s₂) (t₁ ∪ t₂) :=
  ⟨fun a ha => ha.elim (h₁.smul_eq_smul_atom a) (h₂.smul_eq_smul_atom a), fun L hL =>
    hL.elim (h₁.smul_eq_smul_litter L) (h₂.smul_eq_smul_litter L), fun L hL =>
    hL.elim (h₁.left_exact L) (h₂.left_exact L), fun L hL =>
    hL.elim (h₁.right_exact L) (h₂.right_exact L)⟩

theorem _root_.ConNF.NearLitterPerm.Biexact.smul_litter_subset {π π' : NearLitterPerm}
    {atoms : Set Atom} {litters : Set Litter}
    (h : NearLitterPerm.Biexact π π' atoms litters)
    (L : Litter) (hL : L ∈ litters) : (π • L.toNearLitter : Set Atom) ⊆ π' • L.toNearLitter := by
  rw [NearLitterPerm.smul_nearLitter_coe, NearLitterPerm.smul_nearLitter_coe]
  rintro _ ⟨a, ha, rfl⟩
  simp only [Litter.coe_toNearLitter, mem_litterSet] at ha
  by_cases h' : (π • a).1 = π • L
  by_cases h'' : (π'⁻¹ • π • a).1 = L
  · refine' ⟨_, h'', _⟩
    dsimp only
    rw [smul_inv_smul]
  · have := h.right_exact L hL _ (Or.inr ⟨?_, h''⟩)
    · rw [smul_inv_smul, smul_left_cancel_iff, inv_smul_eq_iff] at this
      dsimp only
      rw [this]
      exact ⟨a, ha, rfl⟩
    · rw [smul_inv_smul, h', h.smul_eq_smul_litter L hL]
  · dsimp only
    rw [h.left_exact L hL a (Or.inl ⟨ha, h'⟩)]
    exact ⟨a, ha, rfl⟩

theorem _root_.ConNF.NearLitterPerm.Biexact.smul_litter {π π' : NearLitterPerm} {atoms : Set Atom}
    {litters : Set Litter} (h : NearLitterPerm.Biexact π π' atoms litters) (L : Litter)
    (hL : L ∈ litters) : π • L.toNearLitter = π' • L.toNearLitter := by
  refine' SetLike.coe_injective _
  refine' subset_antisymm _ _
  exact h.smul_litter_subset L hL
  exact h.symm.smul_litter_subset L hL

theorem _root_.ConNF.NearLitterPerm.Biexact.smul_nearLitter {π π' : NearLitterPerm} {atoms : Set Atom}
    {litters : Set Litter} (h : NearLitterPerm.Biexact π π' atoms litters) (N : NearLitter)
    (hN : N.1 ∈ litters) (hN' : litterSet N.1 ∆ N ⊆ atoms) : π • N = π' • N := by
  refine' SetLike.coe_injective _
  conv_lhs => rw [NearLitterPerm.smul_nearLitter_eq_smul_symmDiff_smul]
  conv_rhs => rw [NearLitterPerm.smul_nearLitter_eq_smul_symmDiff_smul]
  refine' congr_arg₂ _ (congr_arg SetLike.coe (h.smul_litter N.1 hN)) _
  ext a : 1
  constructor
  · rintro ⟨b, hb, rfl⟩
    dsimp only
    rw [h.smul_eq_smul_atom b (hN' hb)]
    exact ⟨b, hb, rfl⟩
  · rintro ⟨b, hb, rfl⟩
    dsimp only
    rw [← h.smul_eq_smul_atom b (hN' hb)]
    exact ⟨b, hb, rfl⟩

/- `in_out` is just another way to quantify exceptions, focusing on a slightly different litter.
Basically `in_out` looks only at images not preimages. -/
theorem isException_of_inOut {π : NearLitterPerm} {a : Atom} {L : Litter} :
    InOut π a L → π.IsException a ∨ π.IsException (π • a) := by
  rintro (⟨rfl, ha⟩ | ha)
  · refine' Or.inr (Or.inr _)
    intro h
    rw [mem_litterSet, eq_inv_smul_iff] at h
    rw [← h, inv_smul_smul] at ha
    exact ha rfl
  · refine' Or.inl (Or.inl _)
    rw [mem_litterSet, ha.1, smul_left_cancel_iff]
    exact Ne.symm ha.2

structure Biexact {β : Iio α} (π π' : StructPerm β) (c : SupportCondition β) : Prop where
  smul_eq_smul_atom :
    ∀ A : ExtendedIndex β,
      ∀ a : Atom, (inl a, A) ≤[α] c → StructPerm.derivative A π • a = StructPerm.derivative A π' • a
  smul_eq_smul_litter :
    ∀ A : ExtendedIndex β,
      ∀ L : Litter,
        (inr L.toNearLitter, A) ≤[α] c →
          Flexible α L A → StructPerm.derivative A π • L = StructPerm.derivative A π' • L
  exact :
    ∀ A : ExtendedIndex β,
      ∀ L : Litter,
        (inr L.toNearLitter, A) ≤[α] c →
          StructPerm.derivative A π • L = StructPerm.derivative A π' • L →
            StructPerm.derivative A π • L.toNearLitter = StructPerm.derivative A π' • L.toNearLitter

theorem Biexact.atoms {β : Iio α} {π π' : StructPerm β} {c : SupportCondition β}
    (h : Biexact π π' c) (A : ExtendedIndex β) :
    NearLitterPerm.Biexact (StructPerm.ofBot <| StructPerm.derivative A π)
      (StructPerm.ofBot <| StructPerm.derivative A π') {a | (inl a, A) ≤[α] c} ∅ :=
  NearLitterPerm.Biexact.atoms _ (h.smul_eq_smul_atom A)

theorem Biexact.constrains {β : Iio α} {π π' : StructPerm β} {c d : SupportCondition β}
    (h : Biexact π π' c) (h' : d ≤[α] c) : Biexact π π' d :=
  ⟨fun A a ha => h.smul_eq_smul_atom A a (ha.trans h'), fun A L hL =>
    h.smul_eq_smul_litter A L (hL.trans h'), fun A L hL => h.exact A L (hL.trans h')⟩

theorem Biexact.smul_eq_smul {β : Iio α} {π π' : Allowable β} {c : SupportCondition β}
    (h : Biexact (Allowable.toStructPerm π) (Allowable.toStructPerm π') c) :
    π • c = π' • c := by
  revert h
  refine' WellFounded.induction (C := fun c => Biexact _ _ c → π • c = π' • c)
    (constrains_wf α β) c _
  clear c
  intro c ih h
  obtain ⟨a | N, A⟩ := c <;> refine StructPerm.smul_supportCondition_eq_iff.mpr ?_
  · change inl _ = inl _
    simp only [inl.injEq]
    exact h.smul_eq_smul_atom A a Relation.ReflTransGen.refl
  change inr _ = inr _
  simp only [inr.injEq]
  by_cases hL : N.IsLitter
  swap
  · have :=
      ih _ (Constrains.nearLitter N (NearLitter.not_isLitter hL) A)
        (h.constrains (reflTransGen_nearLitter Relation.ReflTransGen.refl))
    change (inr _, _) = (inr _, _) at this
    simp only [Prod.mk.injEq, inr.injEq, and_true] at this
    refine' SetLike.coe_injective _
    refine' (NearLitterPerm.smul_nearLitter_eq_smul_symmDiff_smul _ _).trans _
    refine' Eq.trans _ (NearLitterPerm.smul_nearLitter_eq_smul_symmDiff_smul _ _).symm
    refine' congr_arg₂ _ (congr_arg SetLike.coe this) _
    ext a : 1
    constructor
    · rintro ⟨b, hb, rfl⟩
      have : (inl _, _) = (inl _, _) :=
        ih _ (Constrains.symmDiff N b hb A)
          (h.constrains (Relation.ReflTransGen.single <| Constrains.symmDiff N b hb A))
      simp only [Prod.mk.injEq, inl.injEq, and_true] at this
      exact ⟨b, hb, this.symm⟩
    · rintro ⟨b, hb, rfl⟩
      have : (inl _, _) = (inl _, _) :=
        ih _ (Constrains.symmDiff N b hb A)
          (h.constrains (Relation.ReflTransGen.single <| Constrains.symmDiff N b hb A))
      simp only [Prod.mk.injEq, inl.injEq, and_true] at this
      exact ⟨b, hb, this⟩
  obtain ⟨L, rfl⟩ := hL.exists_litter_eq
  suffices
    Allowable.toStructPerm π A • L =
    Allowable.toStructPerm π' A • L
    from h.exact _ _ Relation.ReflTransGen.refl this
  obtain hL | hL := flexible_cases α L A
  swap
  · exact h.smul_eq_smul_litter A L Relation.ReflTransGen.refl hL
  induction' hL with γ δ ε hδ hε hδε B t γ ε hε B a
  · have := toStructPerm_smul_fuzz (γ : IicBot α) δ ε
      (coe_lt hδ) (coe_lt hε) (Iio.coe_injective.ne hδε)
    have h₁ := this (Allowable.derivative
      (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B) π) t
    have h₂ := this (Allowable.derivative
      (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B) π') t
    rw [Allowable.toStructPerm_derivative
      (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B)] at h₁ h₂
    simp only [Allowable.derivative_eq] at h₁ h₂
    refine h₁.trans (h₂.trans ?_).symm
    refine' congr_arg _ _
    rw [← inv_smul_eq_iff, smul_smul]
    refine' (designatedSupport t).supports _ _
    intro c hc
    rw [mul_smul, inv_smul_eq_iff]
    rw [Allowable.toStructPerm_smul, Allowable.toStructPerm_smul,
      Allowable.toStructPerm_derivative
        (show Path ((γ : IicBot α) : TypeIndex) (δ : IicBot α) from _),
      Allowable.toStructPerm_derivative
        (show Path ((γ : IicBot α) : TypeIndex) (δ : IicBot α) from _),
      Allowable.toStructPerm_derivative
        (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B),
      Allowable.toStructPerm_derivative
        (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B),
      StructPerm.derivative_derivative, StructPerm.derivative_derivative]
    have := ih (c.fst, (B.cons <| coe_lt hδ).comp c.snd) ?_ ?_
    · rw [StructPerm.smul_supportCondition_eq_iff]
      exact (StructPerm.smul_supportCondition_eq_iff.mp this).symm
    · exact Constrains.fuzz hδ hε hδε _ _ _ hc
    · refine' h.constrains (Relation.ReflTransGen.single _)
      exact Constrains.fuzz hδ hε hδε _ _ _ hc
  · have := toStructPerm_smul_fuzz (γ : IicBot α) ⊥ ε
      (bot_lt_coe _) (coe_lt hε) IioBot.bot_ne_coe
    have h₁ := this (Allowable.derivative
      (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B) π) a
    have h₂ := this (Allowable.derivative
      (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B) π') a
    rw [Allowable.toStructPerm_derivative
      (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B)] at h₁ h₂
    simp only [Allowable.derivative_eq] at h₁ h₂
    refine h₁.trans (h₂.trans ?_).symm
    refine' congr_arg _ _
    refine (derivative_bot_smul_atom _ _ _).trans ?_
    refine ((derivative_bot_smul_atom _ _ _).trans ?_).symm
    rw [Allowable.toStructPerm_derivative
        (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B),
      Allowable.toStructPerm_derivative
        (show Path ((β : IicBot α) : TypeIndex) (γ : IicBot α) from B),
      StructPerm.derivative_apply, StructPerm.derivative_apply]
    have := ih (inl a, B.cons <| bot_lt_coe _) ?_ ?_
    · change (inl _, _) = (inl _, _) at this
      simp only [Prod.mk.injEq, inl.injEq, and_true] at this
      exact this
    · exact Constrains.fuzz_bot hε _ _
    · refine' h.constrains (Relation.ReflTransGen.single _)
      exact Constrains.fuzz_bot hε _ _

theorem Biexact.smul_eq_smul_nearLitter {β : Iio α} {π π' : Allowable β} {A : ExtendedIndex β}
    {N : NearLitter}
    (h : Biexact (Allowable.toStructPerm π) (Allowable.toStructPerm π') (inr N, A)) :
    StructPerm.derivative A (Allowable.toStructPerm π) • N =
    StructPerm.derivative A (Allowable.toStructPerm π') • N := by
  have : (inr _, _) = (inr _, _) := h.smul_eq_smul
  rw [Prod.mk.inj_iff] at this
  exact inr_injective this.1

theorem mem_dom_of_exactlyApproximates {β : Iio α} {π₀ : StructApprox β} {π : StructPerm β}
    (hπ : π₀.ExactlyApproximates π) {A : ExtendedIndex β} {a : Atom} {L : Litter}
    (h : InOut (StructPerm.ofBot <| StructPerm.derivative A π) a L) :
    a ∈ (π₀ A).atomPerm.domain := by
  obtain h | h := isException_of_inOut h
  · exact (hπ A).exception_mem _ h
  · have h₁ := (hπ A).exception_mem _ h
    have := (hπ A).symm_map_atom _ h₁
    rw [inv_smul_smul] at this
    rw [← this]
    exact (π₀ A).atomPerm.symm.map_domain h₁

/--
We can prove that `map_flexible` holds at any `constrained_action` without any `lawful` hypothesis.
-/
theorem constrainedAction_comp_mapFlexible (hπf : π.Free) {γ : Iio α} {s : Set (SupportCondition β)}
    {hs : Small s} (A : Path (β : TypeIndex) γ) :
    ((constrainedAction π s hs).comp A).MapFlexible := by
  rintro L B ⟨c, hc, hL₁⟩ hL₂
  simp only [StructAction.comp_apply, constrainedAction_litterMap,
    foaHypothesis_nearLitterImage]
  rw [completeNearLitterMap_fst_eq]
  obtain hL₃ | (⟨⟨hL₃⟩⟩ | ⟨⟨hL₃⟩⟩) := flexible_cases' _ L (A.comp B)
  · rw [completeLitterMap_eq_of_flexible hL₃]
    refine' NearLitterApprox.flexibleCompletion_smul_flexible _ _ _ _ _ hL₂
    intro L' hL'
    exact flexible_of_comp_flexible (hπf (A.comp B) L' hL')
  · rw [completeLitterMap_eq_of_inflexibleBot hL₃]
    obtain ⟨δ, ε, hε, C, a, rfl, hC⟩ := hL₃
    contrapose hL₂
    rw [not_flexible_iff] at hL₂ ⊢
    rw [Inflexible_iff] at hL₂
    obtain ⟨δ', ε', ζ', _, hζ', hεζ', C', t', h', rfl⟩ | ⟨δ', ε', hε', C', a', h', rfl⟩ := hL₂
    · have := congr_arg Litter.β h'
      simp only [fuzz_β, bot_ne_coe] at this
    · rw [Path.comp_cons, Path.comp_cons] at hC
      cases Subtype.coe_injective (coe_eq_coe.mp (Path.obj_eq_of_cons_eq_cons hC))
      have hC := (Path.heq_of_cons_eq_cons hC).eq
      cases Subtype.coe_injective (coe_eq_coe.mp (Path.obj_eq_of_cons_eq_cons hC))
      exact Inflexible.mk_bot hε _ _
  · rw [completeLitterMap_eq_of_inflexible_coe' hL₃]
    split_ifs
    swap
    · exact hL₂
    obtain ⟨δ, ε, ζ, hε, hζ, hεζ, C, t, rfl, hC⟩ := hL₃
    contrapose hL₂
    rw [not_flexible_iff] at hL₂ ⊢
    rw [Inflexible_iff] at hL₂
    obtain ⟨δ', ε', ζ', hε', hζ', hεζ', C', t', h', rfl⟩ | ⟨δ', ε', hε', C', a', h', rfl⟩ := hL₂
    · rw [Path.comp_cons, Path.comp_cons] at hC
      cases Subtype.coe_injective (coe_eq_coe.mp (Path.obj_eq_of_cons_eq_cons hC))
      have hC := (Path.heq_of_cons_eq_cons hC).eq
      cases Subtype.coe_injective (coe_eq_coe.mp (Path.obj_eq_of_cons_eq_cons hC))
      refine' Inflexible.mk_coe hε hζ hεζ _ _
    · have := congr_arg Litter.β h'
      simp only [fuzz_β, bot_ne_coe] at this
      cases this

theorem ihAction_comp_mapFlexible (hπf : π.Free) {γ : Iio α} (c : SupportCondition β)
    (A : Path (β : TypeIndex) γ) :
    ((ihAction (π.foaHypothesis : Hypothesis c)).comp A).MapFlexible := by
  rw [ihAction_eq_constrainedAction]
  exact constrainedAction_comp_mapFlexible hπf A

theorem ihsAction_comp_mapFlexible (hπf : π.Free) {γ : Iio α} (c d : SupportCondition β)
    (A : Path (β : TypeIndex) γ) : ((ihsAction π c d).comp A).MapFlexible := by
  rw [ihsAction_eq_constrainedAction]
  exact constrainedAction_comp_mapFlexible hπf A

theorem completeLitterMap_flexible (hπf : π.Free) {A : ExtendedIndex β} {L : Litter}
    (h : Flexible α L A) : Flexible α (π.completeLitterMap A L) A := by
  rw [completeLitterMap_eq_of_flexible h]
  exact NearLitterApprox.flexibleCompletion_smul_flexible _ _ _ (hπf A) _ h

theorem completeLitterMap_inflexibleBot {A : ExtendedIndex β} {L : Litter}
    (h : InflexibleBot L A) : InflexibleBot (π.completeLitterMap A L) A := by
  rw [completeLitterMap_eq_of_inflexibleBot h]
  obtain ⟨γ, ε, hγε, B, a, rfl, rfl⟩ := h
  exact ⟨γ, ε, hγε, B, _, rfl, rfl⟩

theorem completeLitterMap_inflexibleCoe (hπf : π.Free) {c d : SupportCondition β}
    (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {L : Litter} (h : InflexibleCoe L A)
    (hL : (inr L.toNearLitter, A) ∈ reflTransConstrained c d) :
    InflexibleCoe (π.completeLitterMap A L) A := by
  rw [completeLitterMap_eq_of_inflexibleCoe h]
  obtain ⟨γ, δ, ε, hδ, hε, hδε, B, a, rfl, rfl⟩ := h
  refine' ⟨_, _, _, hδ, hε, hδε, _, _, rfl, rfl⟩
  · intros A L hL h
    refine' (hcd.le _).comp _
    obtain hL | hL := hL
    · exact (ihAction_le hL).trans (ihAction_le_ihsAction _ _ _)
    · rw [ihsAction_symm]
      exact (ihAction_le hL).trans (ihAction_le_ihsAction _ _ _)
  · intros A L _ h
    exact ihAction_comp_mapFlexible hπf _ _

theorem completeLitterMap_flexible' (hπf : π.Free) {c d : SupportCondition β}
    (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {L : Litter}
    (hL : (inr L.toNearLitter, A) ∈ reflTransConstrained c d)
    (h : Flexible α (π.completeLitterMap A L) A) : Flexible α L A := by
  obtain h' | h' | h' := flexible_cases' β L A
  · exact h'
  · have := completeLitterMap_inflexibleBot (π := π) h'.some
    rw [flexible_iff_not_inflexibleBot_inflexibleCoe] at h
    cases h.1.false this
  · have := completeLitterMap_inflexibleCoe hπf hcd h'.some hL
    rw [flexible_iff_not_inflexibleBot_inflexibleCoe] at h
    cases h.2.false this

theorem completeLitterMap_flexible_iff (hπf : π.Free) {c d : SupportCondition β}
    (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {L : Litter}
    (hL : (inr L.toNearLitter, A) ∈ reflTransConstrained c d) :
    Flexible α (π.completeLitterMap A L) A ↔ Flexible α L A :=
  ⟨completeLitterMap_flexible' hπf hcd hL, completeLitterMap_flexible hπf⟩

theorem completeLitterMap_inflexibleBot' (hπf : π.Free) {c d : SupportCondition β}
    (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {L : Litter}
    (hL : (inr L.toNearLitter, A) ∈ reflTransConstrained c d)
    (h : InflexibleBot (π.completeLitterMap A L) A) : InflexibleBot L A := by
  refine' Nonempty.some _
  obtain h' | h' | h' := flexible_cases' β L A
  · have := completeLitterMap_flexible hπf h'
    rw [flexible_iff_not_inflexibleBot_inflexibleCoe] at this
    cases this.1.false h
  · exact h'
  · have := completeLitterMap_inflexibleCoe hπf hcd h'.some hL
    cases inflexibleBot_inflexibleCoe h this

theorem completeLitterMap_inflexibleBot_iff (hπf : π.Free) {c d : SupportCondition β}
    (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {L : Litter}
    (hL : (inr L.toNearLitter, A) ∈ reflTransConstrained c d) :
    Nonempty (InflexibleBot (π.completeLitterMap A L) A) ↔ Nonempty (InflexibleBot L A) :=
  ⟨fun ⟨h⟩ => ⟨completeLitterMap_inflexibleBot' hπf hcd hL h⟩, fun ⟨h⟩ =>
    ⟨completeLitterMap_inflexibleBot h⟩⟩

theorem completeLitterMap_inflexibleCoe' (hπf : π.Free) {A : ExtendedIndex β} {L : Litter}
    (h : InflexibleCoe (π.completeLitterMap A L) A) : InflexibleCoe L A := by
  refine' Nonempty.some _
  obtain h' | h' | h' := flexible_cases' β L A
  · have := completeLitterMap_flexible hπf h'
    rw [flexible_iff_not_inflexibleBot_inflexibleCoe] at this
    cases this.2.false h
  · have := completeLitterMap_inflexibleBot (π := π) h'.some
    cases inflexibleBot_inflexibleCoe this h
  · exact h'

theorem completeLitterMap_inflexibleCoe_iff (hπf : π.Free) {c d : SupportCondition β}
    (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {L : Litter}
    (hL : (inr L.toNearLitter, A) ∈ reflTransConstrained c d) :
    Nonempty (InflexibleCoe (π.completeLitterMap A L) A) ↔ Nonempty (InflexibleCoe L A) :=
  ⟨fun ⟨h⟩ => ⟨completeLitterMap_inflexibleCoe' hπf h⟩, fun ⟨h⟩ =>
    ⟨completeLitterMap_inflexibleCoe hπf hcd h hL⟩⟩

theorem _root_.ConNF.StructPerm.derivative_fst {α : TypeIndex} (π : StructPerm α)
    (A : ExtendedIndex α) (N : NearLitter) :
    (StructPerm.derivative A π • N).fst = StructPerm.derivative A π • N.fst :=
  rfl

theorem constrainedAction_coherent' (hπf : π.Free) {γ : Iio α} (A : Path (β : TypeIndex) γ)
    (N : ExtendedIndex γ × NearLitter) (s : Set (SupportCondition β)) (hs : Small s)
    (hc : ∃ c : SupportCondition β, c ∈ s ∧ (inr N.2, A.comp N.1) ≤[α] c)
    (hπ : ((constrainedAction π s hs).comp A).Lawful) (ρ : Allowable γ)
    (h : (((constrainedAction π s hs).comp A).rc hπ).ExactlyApproximates
      (Allowable.toStructPerm ρ)) :
    completeNearLitterMap π (A.comp N.1) N.2 =
    StructPerm.derivative N.1 (Allowable.toStructPerm ρ) • N.2 := by
  revert hc
  refine'
    WellFounded.induction
      (C := fun N : ExtendedIndex γ × NearLitter => (∃ c : SupportCondition β, c ∈ s ∧
        Relation.ReflTransGen (Constrains α ↑β) (inr N.snd, Path.comp A N.fst) c) →
        completeNearLitterMap π (Path.comp A N.fst) N.snd =
        StructPerm.derivative N.fst (Allowable.toStructPerm ρ) • N.snd)
      (InvImage.wf (fun N => (inr N.2, N.1)) (WellFounded.transGen (constrains_wf α γ))) N _
  clear N
  rintro ⟨B, N⟩ ih ⟨c, hc₁, hc₂⟩
  dsimp only at *
  have hdom : ((((constrainedAction π s hs).comp A B).refine (hπ B)).litterMap N.fst).Dom :=
    ⟨c, hc₁, reflTransGen_nearLitter hc₂⟩
  suffices completeLitterMap π (A.comp B) N.fst =
      StructPerm.derivative B (Allowable.toStructPerm ρ) • N.fst by
    refine' SetLike.coe_injective _
    refine'
      Eq.trans _
        (NearLitterAction.smul_nearLitter_eq_of_preciseAt _ (h B) hdom
            (NearLitterAction.refine_precise _) this.symm).symm
    rw [completeNearLitterMap_eq' (A.comp B) N]
    simp only [StructAction.refine_apply, StructAction.refine_litterMap,
      foaHypothesis_nearLitterImage, StructPerm.ofBot_smul]
    simp only [StructAction.comp_apply, constrainedAction_litterMap, symmDiff_right_inj]
    ext a : 1
    constructor
    · rintro ⟨a, ha, rfl⟩
      refine' ⟨a, ha, _⟩
      refine' ((h B).map_atom a _).symm.trans _
      · refine' Or.inl (Or.inl (Or.inl (Or.inl _)))
        exact ⟨c, hc₁, Relation.ReflTransGen.head (Constrains.symmDiff N a ha _) hc₂⟩
      · rw [StructAction.rc_smul_atom_eq]
        rfl
        exact ⟨c, hc₁, Relation.ReflTransGen.head (Constrains.symmDiff N a ha _) hc₂⟩
    · rintro ⟨a, ha, rfl⟩
      refine' ⟨a, ha, _⟩
      refine' Eq.trans _ ((h B).map_atom a _)
      · rw [StructAction.rc_smul_atom_eq]
        rfl
        exact ⟨c, hc₁, Relation.ReflTransGen.head (Constrains.symmDiff N a ha _) hc₂⟩
      · refine' Or.inl (Or.inl (Or.inl (Or.inl _)))
        exact ⟨c, hc₁, Relation.ReflTransGen.head (Constrains.symmDiff N a ha _) hc₂⟩
  have hc₂' := reflTransGen_nearLitter hc₂
  generalize hNL : N.fst = L
  rw [hNL] at hdom hc₂'
  obtain hL | ⟨⟨hL⟩⟩ | ⟨⟨hL⟩⟩ := flexible_cases' (γ : Iic α) L B
  · refine' Eq.trans _ ((h B).map_litter L _)
    · rw [StructAction.rc_smul_litter_eq]
      rw [NearLitterAction.flexibleLitterPerm_apply_eq]
      swap; exact hdom
      swap; exact hL
      exact (NearLitterAction.roughLitterMapOrElse_of_dom _ hdom).symm
    · refine' Or.inl (Or.inl _)
      refine' ⟨hdom, hL⟩
  · rw [completeLitterMap_eq_of_inflexibleBot (hL.comp A)]
    obtain ⟨δ, ε, hε, C, a, rfl, rfl⟩ := hL
    rw [StructPerm.derivative_cons, StructPerm.derivative_cons]
    rw [← Allowable.toStructPerm_derivative (show Path ((γ : IicBot α) : TypeIndex) (δ : IicBot α) from C)]
    refine'
      Eq.trans _
        (toStructPerm_smul_fuzz (δ : IicBot α) ⊥ ε (bot_lt_coe _) _ _
            (Allowable.derivative (show Path ((γ : IicBot α) : TypeIndex) (δ : IicBot α) from C) ρ) a).symm
    swap
    · intro h
      cases h
    refine' congr_arg _ _
    rw [Allowable.derivative_cons_apply]
    refine'
      Eq.trans _
        (((h <| C.cons (bot_lt_coe _)).map_atom a
              (Or.inl
                (Or.inl
                  (Or.inl
                    (Or.inl
                      ⟨c, hc₁,
                        Relation.ReflTransGen.head (Constrains.fuzz_bot hε _ _) hc₂'⟩))))).trans
          _)
    · rw [StructAction.rc_smul_atom_eq]
      rfl
      exact ⟨c, hc₁, Relation.ReflTransGen.head (Constrains.fuzz_bot hε _ _) hc₂'⟩
    · simp only [StructPerm.derivative_bot, StructPerm.ofBot_toBot]
      have := derivative_bot_smul_atom (show Allowable (γ : IicBot α) from ρ)
        (show Path ((γ : IicBot α) : TypeIndex) (⊥ : IicBot α) from C.cons (bot_lt_coe _)) a
      dsimp only at this
      rw [this]
  · rw [completeLitterMap_eq_of_inflexibleCoe (hL.comp A)]
    swap
    · rw [InflexibleCoe.comp_B, ← Path.comp_cons, ← StructAction.comp_comp]
      refine' StructAction.Lawful.comp _ _
      refine' hπ.le (StructAction.le_comp (ihAction_le_constrainedAction _ _) _)
      exact ⟨c, hc₁, hc₂'⟩
    swap
    · rw [InflexibleCoe.comp_B, ← Path.comp_cons]
      exact ihAction_comp_mapFlexible hπf _ _
    obtain ⟨δ, ε, ζ, hε, hζ, hεζ, C, t, rfl, rfl⟩ := hL
    generalize_proofs -- Massively speeds up rewrites and simplifications.
    rw [StructPerm.derivative_cons, StructPerm.derivative_cons]
    rw [← Allowable.toStructPerm_derivative (show Path ((γ : IicBot α) : TypeIndex) (δ : IicBot α) from C)]
    refine'
      Eq.trans _
        (toStructPerm_smul_fuzz (δ : IicBot α) ε ζ (coe_lt hε) _ _
            (Allowable.derivative (show Path ((γ : IicBot α) : TypeIndex) (δ : IicBot α) from C) ρ) t).symm
    swap
    · intro h
      refine' hεζ (Subtype.ext _)
      have := congr_arg Subtype.val h
      exact coe_injective this
    refine' congr_arg _ _
    simp only [ne_eq, Path.comp_cons, InflexibleCoe.comp_δ, InflexibleCoe.comp_t]
    rw [Allowable.derivative_cons_apply, ← inv_smul_eq_iff, smul_smul]
    refine' (designatedSupport t).supports _ _
    intro c hct
    rw [mul_smul, inv_smul_eq_iff]
    obtain ⟨a | M, D⟩ := c
    · refine StructPerm.smul_supportCondition_eq_iff.mpr ?_
      change inl _ = inl _
      simp only [inl.injEq]
      rw [Allowable.toStructPerm_derivative
          (show Path ((γ : IicBot α) : TypeIndex) (ε : IicBot α) from _),
        StructPerm.derivative_apply]
      refine' Eq.trans _ ((h _).map_atom a _)
      refine'
        (((ihAction _).hypothesisedAllowable_exactlyApproximates
                    ⟨δ, ε, ζ, hε, hζ, hεζ, A.comp C, t, rfl, rfl⟩ _ _ D).map_atom
                a _).symm.trans
          _
      · refine' Or.inl (Or.inl (Or.inl (Or.inl _)))
        exact Relation.TransGen.single (Constrains.fuzz hε hζ hεζ _ _ _ hct)
      · rw [StructAction.rc_smul_atom_eq, StructAction.rc_smul_atom_eq]
        · simp only [StructAction.comp_apply, ihAction_atomMap, foaHypothesis_atomImage,
            constrainedAction_atomMap]
          simp_rw [← Path.comp_cons]
          rw [Path.comp_assoc]
        · refine' ⟨c, hc₁, Relation.ReflTransGen.head _ hc₂'⟩
          exact constrains_comp (Constrains.fuzz hε hζ hεζ _ _ _ hct) A
        · simp only [StructAction.comp_apply, ihAction_atomMap]
          simp_rw [← Path.comp_cons]
          rw [Path.comp_assoc]
          exact Relation.TransGen.single (constrains_comp (Constrains.fuzz hε hζ hεζ _ _ _ hct) A)
      · refine' Or.inl (Or.inl (Or.inl (Or.inl _)))
        refine' ⟨c, hc₁, Relation.ReflTransGen.head _ hc₂'⟩
        exact constrains_comp (Constrains.fuzz hε hζ hεζ _ _ _ hct) A
    · refine StructPerm.smul_supportCondition_eq_iff.mpr ?_
      change inr _ = inr _
      simp only [inr.injEq]
      refine' Biexact.smul_eq_smul_nearLitter _
      constructor
      · intro E a ha
        have haN :
          (inl a, (C.cons <| coe_lt hε).comp E) <[α]
            (inr N.fst.toNearLitter, (C.cons <| coe_lt hζ).cons (bot_lt_coe _))
        · simp only [hNL]
          refine' Relation.TransGen.tail' _ (Constrains.fuzz hε hζ hεζ _ _ _ hct)
          exact reflTransGen_constrains_comp ha _
        refine'
          ((StructAction.hypothesisedAllowable_exactlyApproximates _
                      ⟨δ, ε, ζ, hε, hζ, hεζ, A.comp C, t, rfl, rfl⟩ _ _ _).map_atom
                  _ _).symm.trans
            _
        · refine' Or.inl (Or.inl (Or.inl (Or.inl _)))
          change _ <[α] _
          simp only [← hNL, Path.comp_assoc, ← Path.comp_cons]
          exact transGen_constrains_comp haN _
        have := (h ?_).map_atom a ?_
        rw [StructAction.rc_smul_atom_eq] at this ⊢
        swap
        · change _ <[α] _
          simp only [← hNL, Path.comp_assoc, ← Path.comp_cons]
          exact transGen_constrains_comp haN _
        swap
        · refine' ⟨c, hc₁, _root_.trans _ hc₂⟩
          swap
          refine' Relation.ReflTransGen.trans (transGen_constrains_comp haN _).to_reflTransGen _
          exact reflTransGen_nearLitter Relation.ReflTransGen.refl
        · simp only [StructAction.comp_apply, ihAction_atomMap, foaHypothesis_atomImage,
            constrainedAction_atomMap, StructPerm.ofBot_smul] at this ⊢
          rw [Allowable.toStructPerm_derivative
              (show Path ((γ : IicBot α) : TypeIndex) (ε : IicBot α) from _),
            StructPerm.derivative_derivative, ← this,
            ← Path.comp_assoc, Path.comp_cons]
        · refine' Or.inl (Or.inl (Or.inl (Or.inl _)))
          refine' ⟨c, hc₁, _root_.trans _ hc₂⟩
          simp only [← hNL, Path.comp_assoc, ← Path.comp_cons]
          exact reflTransGen_constrains_comp (transGen_nearLitter haN).to_reflTransGen _
      · intro E L hL₁ hL₂
        rw [← StructPerm.ofBot_smul]
        refine'
          ((StructAction.hypothesisedAllowable_exactlyApproximates _
                      ⟨δ, ε, ζ, hε, hζ, hεζ, A.comp C, t, rfl, rfl⟩ _ _ _).map_litter
                  _ _).symm.trans
            _
        · refine' Or.inl (Or.inl ⟨_, hL₂⟩)
          refine' Relation.TransGen.trans_right (reflTransGen_constrains_comp hL₁ _) _
          exact Relation.TransGen.single (Constrains.fuzz hε hζ hεζ _ _ _ hct)
        have hLN :
          (inr L.toNearLitter, (C.cons <| coe_lt hε).comp E) <[α]
            (inr N.fst.toNearLitter, (C.cons <| coe_lt hζ).cons (bot_lt_coe _))
        · simp only [hNL]
          refine' Relation.TransGen.tail' _ (Constrains.fuzz hε hζ hεζ _ _ _ hct)
          exact reflTransGen_constrains_comp hL₁ _
        rw [StructAction.rc_smul_litter_eq, NearLitterAction.flexibleLitterPerm_apply_eq,
          NearLitterAction.roughLitterMapOrElse_of_dom]
        simp only [StructAction.comp_apply, StructAction.refine_apply,
          NearLitterAction.refine_litterMap, ihAction_litterMap,
          foaHypothesis_nearLitterImage]
        specialize
          ih ((C.cons <| coe_lt hε).comp E, L.toNearLitter) (transGen_nearLitter hLN)
            ⟨c, hc₁,
              _root_.trans (transGen_constrains_comp (transGen_nearLitter hLN) _).to_reflTransGen hc₂⟩
        · dsimp only at ih
          rw [← Path.comp_assoc, Path.comp_cons] at ih
          rw [ih]
          simp only [StructPerm.derivative_fst, Litter.toNearLitter_fst]
          rw [Allowable.toStructPerm_derivative
              (show Path ((γ : IicBot α) : TypeIndex) (ε : IicBot α) from _),
            StructPerm.derivative_derivative]
        · refine' transGen_nearLitter _
          simp only [← hNL, Path.comp_assoc, ← Path.comp_cons]
          exact transGen_constrains_comp hLN _
        · refine' transGen_nearLitter _
          simp only [← hNL, Path.comp_assoc, ← Path.comp_cons]
          exact transGen_constrains_comp hLN _
        · exact hL₂
      · intro E L hL₁ hL₂
        have hLN :
          (inr L.toNearLitter, (C.cons <| coe_lt hε).comp E) <[α]
            (inr N.fst.toNearLitter, (C.cons <| coe_lt hζ).cons (bot_lt_coe _))
        · simp only [hNL]
          refine' Relation.TransGen.tail' _ (Constrains.fuzz hε hζ hεζ _ _ _ hct)
          exact reflTransGen_constrains_comp hL₁ _
        specialize
          ih ((C.cons <| coe_lt hε).comp E, L.toNearLitter) (transGen_nearLitter hLN)
            ⟨c, hc₁,
              _root_.trans (transGen_constrains_comp (transGen_nearLitter hLN) _).to_reflTransGen hc₂⟩
        simp only at ih
        rw [← Path.comp_assoc, Path.comp_cons] at ih
        refine'
          (NearLitterAction.smul_toNearLitter_eq_of_preciseAt _
                (StructAction.hypothesisedAllowable_exactlyApproximates (ihAction _)
                  ⟨δ, ε, ζ, hε, hζ, hεζ, A.comp C, t, rfl, rfl⟩ _ _ _)
                _ (NearLitterAction.refine_precise _) _).trans
            _
        · refine' Relation.TransGen.tail' (reflTransGen_constrains_comp hL₁ _) _
          exact Constrains.fuzz hε hζ hεζ _ _ _ hct
        · refine' hL₂.trans _
          simp only [StructAction.comp_apply, StructAction.refine_apply,
            NearLitterAction.refine_litterMap, ihAction_litterMap,
            foaHypothesis_nearLitterImage]
          rw [ih,
            Allowable.toStructPerm_derivative
              (show Path ((γ : IicBot α) : TypeIndex) (ε : IicBot α) from _),
            StructPerm.derivative_derivative]
          rfl
        · simp only [StructAction.comp_apply, StructAction.refine_apply,
            NearLitterAction.refine_litterMap, ihAction_litterMap,
            foaHypothesis_nearLitterImage]
          rw [ih,
            Allowable.toStructPerm_derivative
              (show Path ((γ : IicBot α) : TypeIndex) (ε : IicBot α) from _),
            StructPerm.derivative_derivative]

/-- **Coherence lemma**: The action of the complete litter map, below a given support condition `c`,
is equal to the action of any allowable permutation that exactly approximates it.
This condition can only be applied for `γ < α` as we're dealing with lower allowable permutations.
-/
theorem constrainedAction_coherent (hπf : π.Free) {γ : Iio α} (A : Path (β : TypeIndex) γ)
    (B : ExtendedIndex γ) (N : NearLitter) (s : Set (SupportCondition β)) (hs : Small s)
    (hc : ∃ c : SupportCondition β, c ∈ s ∧ (inr N, A.comp B) ≤[α] c)
    (hπ : ((constrainedAction π s hs).comp A).Lawful) (ρ : Allowable γ)
    (h : (((constrainedAction π s hs).comp A).rc hπ).ExactlyApproximates
      (Allowable.toStructPerm ρ)) :
    completeNearLitterMap π (A.comp B) N = StructPerm.derivative B (Allowable.toStructPerm ρ) • N :=
  constrainedAction_coherent' hπf A (B, N) s hs hc hπ ρ h

/-- The coherence lemma for atoms, which is much easier to prove.
The statement is here for symmetry.
-/
theorem constrainedAction_coherent_atom {γ : Iio α}
    (A : Path (β : TypeIndex) γ) (B : ExtendedIndex γ) (a : Atom) (s : Set (SupportCondition β))
    (hs : Small s) (hc : ∃ c : SupportCondition β, c ∈ s ∧ (inl a, A.comp B) ≤[α] c)
    (hπ : ((constrainedAction π s hs).comp A).Lawful) (ρ : Allowable γ)
    (h : (((constrainedAction π s hs).comp A).rc hπ).ExactlyApproximates
      (Allowable.toStructPerm ρ)) :
    completeAtomMap π (A.comp B) a = StructPerm.derivative B (Allowable.toStructPerm ρ) • a := by
  refine' Eq.trans _ ((h B).map_atom a (Or.inl (Or.inl (Or.inl (Or.inl hc)))))
  rw [StructAction.rc_smul_atom_eq]
  rfl
  exact hc

theorem ihsAction_coherent (hπf : π.Free) {γ : Iio α} (A : Path (β : TypeIndex) γ)
    (B : ExtendedIndex γ) (N : NearLitter) (c d : SupportCondition β)
    (hc : (inr N, A.comp B) ∈ transConstrained c d) (hπ : ((ihsAction π c d).comp A).Lawful)
    (ρ : Allowable γ) (h : (((ihsAction π c d).comp A).rc hπ).ExactlyApproximates
      (Allowable.toStructPerm ρ)) :
    completeNearLitterMap π (A.comp B) N =
    StructPerm.derivative B (Allowable.toStructPerm ρ) • N := by
  simp_rw [ihsAction_eq_constrainedAction] at hπ
  refine constrainedAction_coherent hπf A B N _ _ ?_ hπ ρ ?_
  obtain hc | hc := hc
  · simp only [Relation.TransGen.tail'_iff] at hc
    obtain ⟨d, hd₁, hd₂⟩ := hc
    exact ⟨d, Or.inl hd₂, hd₁⟩
  · simp only [Relation.TransGen.tail'_iff] at hc
    obtain ⟨d, hd₁, hd₂⟩ := hc
    exact ⟨d, Or.inr hd₂, hd₁⟩
  · convert h
    rw [ihsAction_eq_constrainedAction]

theorem ihsAction_coherent_atom {γ : Iio α} (A : Path (β : TypeIndex) γ)
    (B : ExtendedIndex γ) (a : Atom) (c d : SupportCondition β) (hc : (inl a, A.comp B) <[α] c)
    (hπ : ((ihsAction π c d).comp A).Lawful) (ρ : Allowable γ)
    (h : (((ihsAction π c d).comp A).rc hπ).ExactlyApproximates (Allowable.toStructPerm ρ)) :
    completeAtomMap π (A.comp B) a = StructPerm.derivative B (Allowable.toStructPerm ρ) • a := by
  refine' Eq.trans _ ((h B).map_atom a (Or.inl (Or.inl (Or.inl (Or.inl (Or.inl hc))))))
  rw [StructAction.rc_smul_atom_eq]
  rfl
  exact Or.inl hc

theorem ihAction_coherent (hπf : π.Free) {γ : Iio α} (A : Path (β : TypeIndex) γ)
    (B : ExtendedIndex γ) (N : NearLitter) (c : SupportCondition β) (hc : (inr N, A.comp B) <[α] c)
    (hπ : ((ihAction (π.foaHypothesis : Hypothesis c)).comp A).Lawful) (ρ : Allowable γ)
    (h : (((ihAction (π.foaHypothesis : Hypothesis c)).comp A).rc hπ).ExactlyApproximates
        (Allowable.toStructPerm ρ)) :
    completeNearLitterMap π (A.comp B) N =
    StructPerm.derivative B (Allowable.toStructPerm ρ) • N := by
  refine' ihsAction_coherent hπf A B N c c (Or.inl hc) _ ρ _
  · rw [ihsAction_self]
    exact hπ
  · convert h
    rw [ihsAction_self]

theorem ihAction_coherent_atom {γ : Iio α} (A : Path (β : TypeIndex) γ)
    (B : ExtendedIndex γ) (a : Atom) (c : SupportCondition β) (hc : (inl a, A.comp B) <[α] c)
    (hπ : ((ihAction (π.foaHypothesis : Hypothesis c)).comp A).Lawful) (ρ : Allowable γ)
    (h :
      (((ihAction (π.foaHypothesis : Hypothesis c)).comp A).rc hπ).ExactlyApproximates
        (Allowable.toStructPerm ρ)) :
    completeAtomMap π (A.comp B) a = StructPerm.derivative B (Allowable.toStructPerm ρ) • a := by
  refine' ihsAction_coherent_atom A B a c c hc _ ρ _
  · rw [ihsAction_self]
    exact hπ
  · convert h
    rw [ihsAction_self]

theorem ihAction_smul_tangle' (hπf : π.Free) (c d : SupportCondition β) (A : ExtendedIndex β)
    (L : Litter) (hL₁ : (inr L.toNearLitter, A) ≤[α] c) (hL₂ : InflexibleCoe L A) (hlaw₁ hlaw₂) :
    (ihAction (π.foaHypothesis : Hypothesis (inr L.toNearLitter, A))).hypothesisedAllowable hL₂
          hlaw₁ (ihAction_comp_mapFlexible hπf _ _) •
        hL₂.t =
      (ihsAction π c d).hypothesisedAllowable hL₂ hlaw₂ (ihsAction_comp_mapFlexible hπf _ _ _) •
        hL₂.t := by
  obtain ⟨γ, δ, ε, hδ, hε, hδε, B, t, rfl, rfl⟩ := hL₂
  rw [← inv_smul_eq_iff, smul_smul]
  refine' (designatedSupport t).supports _ _
  intro e he
  rw [mul_smul, inv_smul_eq_iff]
  refine StructPerm.smul_supportCondition_eq_iff.mpr ?_
  obtain ⟨a | N, C⟩ := e
  · change inl _ = inl _
    simp only [inl.injEq]
    refine'
      Eq.trans _
        (ihsAction_coherent_atom _ _ a c d _ hlaw₂ _
          ((ihsAction π c d).hypothesisedAllowable_exactlyApproximates _ _ _))
    have := ihAction_coherent_atom (π := π) (B.cons ?_) C a
        (inr (Litter.toNearLitter (fuzz (coe_ne_coe.mpr <| coe_ne' hδε) t)),
          Path.cons (Path.cons B (coe_lt hε)) (bot_lt_coe _))
        ?_ hlaw₁ _
        ((ihAction π.foaHypothesis).hypothesisedAllowable_exactlyApproximates
          ⟨γ, δ, ε, hδ, hε, hδε, B, t, rfl, rfl⟩ ?_ ?_)
    exact this.symm
    · exact Relation.TransGen.single (Constrains.fuzz hδ hε hδε B t _ he)
    · exact Relation.TransGen.head' (Constrains.fuzz hδ hε hδε B t _ he) hL₁
  · change inr _ = inr _
    simp only [inr.injEq]
    refine'
      Eq.trans _
        (ihsAction_coherent hπf _ _ N c d _ hlaw₂ _
          ((ihsAction π c d).hypothesisedAllowable_exactlyApproximates _ _ _))
    have := ihAction_coherent hπf (B.cons ?_) C N
        (inr (Litter.toNearLitter (fuzz (coe_ne_coe.mpr <| coe_ne' hδε) t)),
          Path.cons (Path.cons B (coe_lt hε)) (bot_lt_coe _))
        ?_ hlaw₁ _
        ((ihAction π.foaHypothesis).hypothesisedAllowable_exactlyApproximates
          ⟨γ, δ, ε, hδ, hε, hδε, B, t, rfl, rfl⟩ ?_ ?_)
    exact this.symm
    · exact Relation.TransGen.single (Constrains.fuzz hδ hε hδε B t _ he)
    · exact Or.inl (Relation.TransGen.head' (Constrains.fuzz hδ hε hδε B t _ he) hL₁)

theorem ihAction_smul_tangle (hπf : π.Free) (c d : SupportCondition β) (A : ExtendedIndex β)
    (L : Litter) (hL₁ : (inr L.toNearLitter, A) ∈ reflTransConstrained c d)
    (hL₂ : InflexibleCoe L A) (hlaw₁ hlaw₂) :
    (ihAction (π.foaHypothesis : Hypothesis (inr L.toNearLitter, A))).hypothesisedAllowable hL₂
          hlaw₁ (ihAction_comp_mapFlexible hπf _ _) •
        hL₂.t =
      (ihsAction π c d).hypothesisedAllowable hL₂ hlaw₂ (ihsAction_comp_mapFlexible hπf _ _ _) •
        hL₂.t := by
  obtain hL₁ | hL₁ := hL₁
  · exact ihAction_smul_tangle' hπf c d A L hL₁ hL₂ hlaw₁ hlaw₂
  · have := ihAction_smul_tangle' hπf d c A L hL₁ hL₂ hlaw₁ ?_
    · simp_rw [ihsAction_symm] at this
      exact this
    · rw [ihsAction_symm]
      exact hlaw₂

theorem litter_injective_extends (hπf : π.Free) {c d : SupportCondition β}
    (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {L₁ L₂ : Litter}
    (h₁ : (inr L₁.toNearLitter, A) ∈ reflTransConstrained c d)
    (h₂ : (inr L₂.toNearLitter, A) ∈ reflTransConstrained c d)
    (h : completeLitterMap π A L₁ = completeLitterMap π A L₂) : L₁ = L₂ := by
  obtain h₁' | h₁' | h₁' := flexible_cases' β L₁ A
  · have h₂' : Flexible α L₂ A
    · have := completeLitterMap_flexible hπf h₁'
      rw [h] at this
      exact completeLitterMap_flexible' hπf hcd h₂ this
    rw [completeLitterMap_eq_of_flexible h₁', completeLitterMap_eq_of_flexible h₂'] at h
    refine' LocalPerm.injOn _ _ _ h
    all_goals
      rw [NearLitterApprox.flexibleCompletion_litterPerm_domain_free _ _ _ (hπf A)]
      assumption
  · obtain ⟨h₁'⟩ := h₁'
    have h₂' : InflexibleBot L₂ A
    · have := completeLitterMap_inflexibleBot (π := π) h₁'
      rw [h] at this
      exact completeLitterMap_inflexibleBot' hπf hcd h₂ this
    rw [completeLitterMap_eq_of_inflexibleBot h₁',
      completeLitterMap_eq_of_inflexibleBot h₂'] at h
    obtain ⟨γ₁, ε₁, hγε₁, B₁, a₁, rfl, rfl⟩ := h₁'
    obtain ⟨γ₂, ε₂, hγε₂, B₂, a₂, rfl, hB⟩ := h₂'
    cases Subtype.coe_injective (coe_injective (Path.obj_eq_of_cons_eq_cons hB))
    cases Subtype.coe_injective
      (coe_injective (Path.obj_eq_of_cons_eq_cons (Path.heq_of_cons_eq_cons hB).eq))
    cases (Path.heq_of_cons_eq_cons (Path.heq_of_cons_eq_cons hB).eq).eq
    refine' congr_arg _ ((hcd _).atomMap_injective _ _ (fuzz_injective bot_ne_coe h))
    · have := Constrains.fuzz_bot hγε₁ B₁ a₁
      exact transConstrained_of_reflTransConstrained_of_trans_constrains h₁
        (Relation.TransGen.single this)
    · have := Constrains.fuzz_bot hγε₁ B₁ a₂
      exact transConstrained_of_reflTransConstrained_of_trans_constrains h₂
        (Relation.TransGen.single this)
  · obtain ⟨h₁'⟩ := h₁'
    have h₂' : InflexibleCoe L₂ A
    · have := completeLitterMap_inflexibleCoe hπf hcd h₁' h₁
      rw [h] at this
      exact completeLitterMap_inflexibleCoe' hπf this
    rw [completeLitterMap_eq_of_inflexibleCoe h₁'] at h
    swap
    · refine' (hcd.le _).comp _
      obtain h₁ | h₁ := h₁
      · exact (ihAction_le h₁).trans (ihAction_le_ihsAction _ _ _)
      · rw [ihsAction_symm]
        exact (ihAction_le h₁).trans (ihAction_le_ihsAction _ _ _)
    swap
    · exact ihAction_comp_mapFlexible hπf _ _
    rw [completeLitterMap_eq_of_inflexibleCoe h₂'] at h
    swap
    · refine' (hcd.le _).comp _
      obtain h₂ | h₂ := h₂
      · exact (ihAction_le h₂).trans (ihAction_le_ihsAction _ _ _)
      · rw [ihsAction_symm]
        exact (ihAction_le h₂).trans (ihAction_le_ihsAction _ _ _)
    swap
    · exact ihAction_comp_mapFlexible hπf _ _
    obtain ⟨γ₁, δ₁, ε₁, hδ₁, hε₁, hδε₁, B₁, t₁, rfl, rfl⟩ := h₁'
    obtain ⟨γ₂, δ₂, ε₂, hδ₂, hε₂, hδε₂, B₂, t₂, rfl, hB⟩ := h₂'
    cases Subtype.coe_injective (coe_injective (Path.obj_eq_of_cons_eq_cons hB))
    cases Subtype.coe_injective
      (coe_injective (Path.obj_eq_of_cons_eq_cons (Path.heq_of_cons_eq_cons hB).eq))
    cases (Path.heq_of_cons_eq_cons (Path.heq_of_cons_eq_cons hB).eq).eq
    have := congr_arg Litter.β h
    cases Subtype.coe_injective (coe_injective this)
    clear this
    refine' congr_arg _ _
    have h' := fuzz_injective _ h
    rw [ihAction_smul_tangle hπf c d _ _ h₁ _ _ (hcd.comp _)] at h'
    rw [ihAction_smul_tangle hπf c d _ _ h₂ _ _ (hcd.comp _)] at h'
    rw [StructAction.hypothesisedAllowable_eq t₁ t₂ rfl (hcd.comp _)
        (ihsAction_comp_mapFlexible hπf _ _ _)] at h'
    rw [smul_left_cancel_iff] at h'
    exact h'

/-- **Split relation**
Let `<` denote a relation on `α`.
The split relation `<ₛ` defined on `α × α` is defined by:

* `a < b → (a, c) <ₛ (b, c)` (left `<`)
* `b < c → (a, b) <ₛ (a, c)` (right `<`)
* `a < c → b < c → (a, b) <ₛ (c, d)` (left split)
* `a < d → b < d → (a, b) <ₛ (c, d)` (right split)

This is more granular than the standard product of relations,
which would be given by just the first two constructors.
The splitting constructors allow one to "split" either `c` or `d` into two lower values `a` and `b`.

Splitting has applications with well-founded relations; in particular, `<ₛ` is well-founded whenever
`<` is, so this relation can simplify certain inductive steps.
-/
inductive SplitLt {α : Type _} (r : α → α → Prop) : α × α → α × α → Prop
  | left_lt ⦃a b c : α⦄ : r a b → SplitLt r (a, c) (b, c)
  | right_lt ⦃a b c : α⦄ : r b c → SplitLt r (a, b) (a, c)
  | left_split ⦃a b c d : α⦄ : r a c → r b c → SplitLt r (a, b) (c, d)
  | right_split ⦃a b c d : α⦄ : r a d → r b d → SplitLt r (a, b) (c, d)

theorem le_wellOrderExtension_lt {α : Type _} {r : α → α → Prop} (hr : WellFounded r) :
    r ≤ hr.wellOrderExtension.lt := fun _ _ h => Prod.Lex.left _ _ (hr.rank_lt_of_rel h)

theorem lex_lt_of_splitLt {α : Type _} {r : α → α → Prop} (hr : WellFounded r) :
    SplitLt r ≤
      InvImage (Prod.Lex hr.wellOrderExtension.lt hr.wellOrderExtension.lt) fun a =>
        if hr.wellOrderExtension.lt a.1 a.2 then (a.2, a.1) else (a.1, a.2) := by
  intro a b h
  induction' h with a b c h a b c h a b c d ha hb a b c d ha hb
  · change Prod.Lex _ _ _ _
    simp only
    split_ifs with h₁ h₂ h₂
    · exact Prod.Lex.right _ (le_wellOrderExtension_lt hr _ _ h)
    · by_cases hcb : c = b
      · cases hcb
        exact Prod.Lex.right _ h₁
      · refine' Prod.Lex.left _ _ _
        have := (@not_lt _ hr.wellOrderExtension _ _).mp h₂
        exact @lt_of_le_of_ne _ hr.wellOrderExtension.toPartialOrder _ _ this hcb
    · cases h₁ (@lt_trans _ hr.wellOrderExtension.toPartialOrder.toPreorder _ _ _
        (le_wellOrderExtension_lt hr _ _ h) h₂)
    · exact Prod.Lex.left _ _ (le_wellOrderExtension_lt hr _ _ h)
  · change Prod.Lex _ _ _ _
    simp only
    split_ifs with h₁ h₂ h₂
    · exact Prod.Lex.left _ _ (le_wellOrderExtension_lt hr _ _ h)
    · cases h₂ (@lt_trans _ hr.wellOrderExtension.toPartialOrder.toPreorder _ _ _
        h₁ (le_wellOrderExtension_lt hr _ _ h))
    · exact Prod.Lex.left _ _ h₂
    · exact Prod.Lex.right _ (le_wellOrderExtension_lt hr _ _ h)
  · change Prod.Lex _ _ _ _
    simp only
    split_ifs with h₁ h₂ h₂
    · exact Prod.Lex.left _ _ (@lt_trans _ hr.wellOrderExtension.toPartialOrder.toPreorder _ _ _
        (le_wellOrderExtension_lt hr _ _ hb) h₂)
    · exact Prod.Lex.left _ _ (le_wellOrderExtension_lt hr _ _ hb)
    · exact Prod.Lex.left _ _ (@lt_trans _ hr.wellOrderExtension.toPartialOrder.toPreorder _ _ _
        (le_wellOrderExtension_lt hr _ _ ha)  h₂)
    · exact Prod.Lex.left _ _ (le_wellOrderExtension_lt hr _ _ ha)
  · change Prod.Lex _ _ _ _
    simp only
    split_ifs with h₁ h₂ h₂
    · exact Prod.Lex.left _ _ (le_wellOrderExtension_lt hr _ _ hb)
    · by_cases hcb : c = b
      · cases hcb
        exact Prod.Lex.right _ (le_wellOrderExtension_lt hr _ _ ha)
      · refine' Prod.Lex.left _ _ _
        have := (@not_lt _ hr.wellOrderExtension _ _).mp h₂
        exact
          @lt_of_lt_of_le _
            hr.wellOrderExtension.toPartialOrder.toPreorder _ _
            _ (le_wellOrderExtension_lt hr _ _ hb) this
    · exact Prod.Lex.left _ _ (le_wellOrderExtension_lt hr _ _ ha)
    · have := (@not_lt _ hr.wellOrderExtension _ _).mp h₂
      have :=
        @lt_of_lt_of_le _
          hr.wellOrderExtension.toPartialOrder.toPreorder _ _ _
          (le_wellOrderExtension_lt hr _ _ ha) this
      exact Prod.Lex.left _ _ this

theorem splitLt_wellFounded {α : Type _} {r : α → α → Prop} (hr : WellFounded r) :
    WellFounded (SplitLt r) := by
  refine' Subrelation.wf @(lex_lt_of_splitLt hr) _
  refine' InvImage.wf _ (InvImage.wf _ _)
  refine' WellFounded.prod_lex _ _ <;>
    exact (WellFounded.wellOrderExtension.isWellFounded_lt hr).wf

-- TODO: Clean this up. Proof comes from an old lemma.
theorem completeAtomMap_mem_completeNearLitterMap_toNearLitter' (hπf : π.Free)
    {c d : SupportCondition β} (hcd : (ihsAction π c d).Lawful) {A : ExtendedIndex β} {a : Atom}
    {L : Litter} (ha : a.1 = L) (hL : (inr L.toNearLitter, A) ∈ reflTransConstrained c d) :
    π.completeAtomMap A a ∈ π.completeNearLitterMap A L.toNearLitter := by
  subst ha
  rw [completeNearLitterMap_eq]
  by_cases ha : a ∈ (π A).atomPerm.domain
  · rw [completeAtomMap_eq_of_mem_domain ha]
    refine' Or.inl ⟨Or.inr ⟨a, ⟨rfl, ha⟩, rfl⟩, _⟩
    rintro ⟨_, ⟨b, rfl⟩, _, ⟨hb, rfl⟩, hab⟩
    simp only [foaHypothesis_atomImage, mem_singleton_iff] at hab
    rw [completeAtomMap_eq_of_not_mem_domain hb.2] at hab
    have := Sublitter.equiv_apply_mem (S := (π A).largestSublitter b.fst)
      (T := (π A).largestSublitter (completeLitterMap π A b.fst)) ⟨b, rfl, hb.2⟩
    rw [← hab] at this
    exact this.2 ((π A).atomPerm.map_domain ha)
  rw [completeAtomMap_eq_of_not_mem_domain ha]
  refine' Or.inl ⟨Or.inl _, _⟩
  · rw [SetLike.mem_coe]
    convert Sublitter.equiv_apply_mem _ using 1
    rw [nearLitterHypothesis_eq, completeLitterMap_eq]
    rfl
  · rintro ⟨_, ⟨b, rfl⟩, _, ⟨hb, rfl⟩, hab⟩
    simp only [foaHypothesis_atomImage, mem_singleton_iff] at hab
    rw [completeAtomMap_eq_of_not_mem_domain hb.2] at hab
    have := litter_injective_extends hπf hcd hL
      (fst_mem_reflTransConstrained_of_mem_symmDiff hb.1 hL) ?_
    · rw [Sublitter.equiv_congr_left (congr_arg _ this) _,
        Sublitter.equiv_congr_right (congr_arg _ (congr_arg₂ _ rfl this)) _,
        Subtype.coe_inj, EquivLike.apply_eq_iff_eq] at hab
      cases hab
      exact hb.1.elim (fun h' => h'.2 rfl) fun h' => h'.2 rfl
    exact equiv_apply_eq hab

theorem ihsAction_lawful_extends (hπf : π.Free) (c d : SupportCondition β)
    (hπ : ∀ e f, SplitLt (fun c d => c <[α] d) (e, f) (c, d) → (ihsAction π e f).Lawful) :
    (ihsAction π c d).Lawful := by
  intro A
  have litter_map_injective :
    ∀ ⦃L₁ L₂ : Litter⦄,
      (inr L₁.toNearLitter, A) ∈ transConstrained c d →
      (inr L₂.toNearLitter, A) ∈ transConstrained c d →
      ((π.completeNearLitterMap A L₁.toNearLitter : Set Atom) ∩
        (π.completeNearLitterMap A L₂.toNearLitter : Set Atom)).Nonempty →
      L₁ = L₂ := by
    intro L₁ L₂ h₁ h₂ h₁₂
    have := eq_of_completeLitterMap_inter_nonempty h₁₂
    obtain h₁ | h₁ := h₁ <;> obtain h₂ | h₂ := h₂
    · specialize hπ (inr L₁.toNearLitter, A) (inr L₂.toNearLitter, A) (SplitLt.left_split h₁ h₂)
      exact litter_injective_extends hπf hπ (Or.inl Relation.ReflTransGen.refl)
        (Or.inr Relation.ReflTransGen.refl) this
    · specialize hπ (inr L₁.toNearLitter, A) d (SplitLt.left_lt h₁)
      exact litter_injective_extends hπf hπ
        (Or.inl Relation.ReflTransGen.refl) (Or.inr h₂.to_reflTransGen) this
    · specialize hπ c (inr L₁.toNearLitter, A) (SplitLt.right_lt h₁)
      exact litter_injective_extends hπf hπ
        (Or.inr Relation.ReflTransGen.refl) (Or.inl h₂.to_reflTransGen) this
    · specialize hπ (inr L₁.toNearLitter, A) (inr L₂.toNearLitter, A) (SplitLt.right_split h₁ h₂)
      exact litter_injective_extends hπf hπ (Or.inl Relation.ReflTransGen.refl)
        (Or.inr Relation.ReflTransGen.refl) this
  constructor
  · intro a b ha hb hab
    simp only [ihsAction_atomMap] at ha hb hab
    obtain ha | ha := ha <;> obtain hb | hb := hb
    · specialize hπ (inl a, A) (inl b, A) (SplitLt.left_split ha hb)
      exact atom_injective_extends hπ (Or.inl Relation.ReflTransGen.refl)
        (Or.inr Relation.ReflTransGen.refl) hab
    · specialize hπ (inl a, A) d (SplitLt.left_lt ha)
      exact atom_injective_extends hπ
        (Or.inl Relation.ReflTransGen.refl) (Or.inr hb.to_reflTransGen) hab
    · specialize hπ c (inl a, A) (SplitLt.right_lt ha)
      exact atom_injective_extends hπ
        (Or.inr Relation.ReflTransGen.refl) (Or.inl hb.to_reflTransGen) hab
    · specialize hπ (inl a, A) (inl b, A) (SplitLt.right_split ha hb)
      exact atom_injective_extends hπ (Or.inl Relation.ReflTransGen.refl)
        (Or.inr Relation.ReflTransGen.refl) hab
  · exact litter_map_injective
  · intro a ha L hL
    simp only [ihsAction_atomMap, ihsAction_litterMap]
    have : π.completeAtomMap A a ∈ π.completeNearLitterMap A a.fst.toNearLitter :=by
      obtain ha | ha := ha <;> obtain hL | hL := hL
      · specialize hπ (inl a, A) (inr L.toNearLitter, A) (SplitLt.left_split ha hL)
        exact completeAtomMap_mem_completeNearLitterMap_toNearLitter' hπf hπ rfl
          (fst_mem_refl_trans_constrained' (Or.inl Relation.ReflTransGen.refl))
      · specialize hπ (inl a, A) d (SplitLt.left_lt ha)
        exact completeAtomMap_mem_completeNearLitterMap_toNearLitter' hπf hπ rfl
          (fst_mem_refl_trans_constrained' (Or.inl Relation.ReflTransGen.refl))
      · specialize hπ c (inl a, A) (SplitLt.right_lt ha)
        exact completeAtomMap_mem_completeNearLitterMap_toNearLitter' hπf hπ rfl
          (fst_mem_refl_trans_constrained' (Or.inr Relation.ReflTransGen.refl))
      · specialize hπ (inl a, A) (inr L.toNearLitter, A) (SplitLt.right_split ha hL)
        exact
          completeAtomMap_mem_completeNearLitterMap_toNearLitter' hπf hπ rfl
            (fst_mem_refl_trans_constrained' (Or.inl Relation.ReflTransGen.refl))
    constructor
    · rintro rfl
      exact this
    · intro h
      exact litter_map_injective (fst_mem_trans_constrained' ha) hL ⟨_, this, h⟩

/-- Every `ihs_action` is lawful. This is a consequence of all of the previous lemmas. -/
theorem ihsAction_lawful (hπf : π.Free) (c d : SupportCondition β) : (ihsAction π c d).Lawful := by
  refine WellFounded.induction (C := fun c => (ihsAction π c.1 c.2).Lawful)
    (splitLt_wellFounded (trans_constrains_wf α β)) (c, d) ?_
  rintro ⟨c, d⟩ ih
  exact ihsAction_lawful_extends hπf c d fun e f hef => ih (e, f) hef

theorem ihAction_lawful (hπf : π.Free) (c : SupportCondition β) :
    (ihAction (π.foaHypothesis : Hypothesis c)).Lawful := by
  rw [← ihsAction_self]
  exact ihsAction_lawful hπf c c

/-!
We now establish a number of key consequences of `ihs_action_lawful`, such as injectivity.
-/

/-- The complete atom map is injective. -/
theorem completeAtomMap_injective (hπf : π.Free) (A : ExtendedIndex β) :
    Injective (π.completeAtomMap A) := fun a b =>
  atom_injective_extends (ihsAction_lawful hπf (inl a, A) (inl b, A))
    (Or.inl Relation.ReflTransGen.refl) (Or.inr Relation.ReflTransGen.refl)

/-- The complete litter map is injective. -/
theorem completeLitterMap_injective (hπf : π.Free) (A : ExtendedIndex β) :
    Injective (π.completeLitterMap A) := fun L₁ L₂ =>
  litter_injective_extends hπf
    (ihsAction_lawful hπf (inr L₁.toNearLitter, A) (inr L₂.toNearLitter, A))
    (Or.inl Relation.ReflTransGen.refl) (Or.inr Relation.ReflTransGen.refl)

/-- Atoms inside litters are mapped inside the corresponding image near-litter. -/
theorem completeAtomMap_mem_completeNearLitterMap_toNearLitter (hπf : π.Free) {A : ExtendedIndex β}
    {a : Atom} {L : Litter} :
    π.completeAtomMap A a ∈ π.completeNearLitterMap A L.toNearLitter ↔ a.1 = L := by
  have := completeAtomMap_mem_completeNearLitterMap_toNearLitter' hπf
    (ihsAction_lawful hπf (inl a, A) (inl a, A)) rfl
    (fst_mem_refl_trans_constrained' (Or.inl Relation.ReflTransGen.refl))
  constructor
  · intro h
    exact completeLitterMap_injective hπf _ (eq_of_completeLitterMap_inter_nonempty ⟨_, this, h⟩)
  · rintro rfl
    exact this

theorem mem_image_iff {α β : Type _} {f : α → β} (hf : Injective f) (x : α) (s : Set α) :
    f x ∈ f '' s ↔ x ∈ s :=
  Set.InjOn.mem_image_iff (hf.injOn Set.univ) (subset_univ _) (mem_univ _)

/-- Atoms inside near litters are mapped inside the corresponding image near-litter. -/
theorem completeAtomMap_mem_completeNearLitterMap (hπf : π.Free) {A : ExtendedIndex β} {a : Atom}
    {N : NearLitter} : π.completeAtomMap A a ∈ π.completeNearLitterMap A N ↔ a ∈ N := by
  rw [← SetLike.mem_coe, completeNearLitterMap_eq', Set.symmDiff_def]
  simp only [mem_union, mem_diff, SetLike.mem_coe, not_exists, not_and,
    symmDiff_symmDiff_cancel_left]
  rw [completeAtomMap_mem_completeNearLitterMap_toNearLitter hπf]
  rw [mem_image_iff (completeAtomMap_injective hπf A)]
  simp only [← mem_litterSet, ← mem_diff, ← mem_union]
  rw [← Set.symmDiff_def, symmDiff_symmDiff_cancel_left]
  rw [SetLike.mem_coe]

/-- The complete near-litter map is injective. -/
theorem completeNearLitterMap_injective (hπf : π.Free) (A : ExtendedIndex β) :
    Injective (π.completeNearLitterMap A) := by
  intro N₁ N₂ h
  rw [← SetLike.coe_set_eq, Set.ext_iff] at h ⊢
  intro a
  specialize h (π.completeAtomMap A a)
  simp only [SetLike.mem_coe, completeAtomMap_mem_completeNearLitterMap hπf] at h ⊢
  exact h

end StructApprox

end ConNF
