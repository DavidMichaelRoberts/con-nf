import ConNF.Foa
import ConNF.Counting.OrdSupportEquiv
import ConNF.Counting.Spec

/-!
# Specifying two strong supports at once
-/

open Quiver Set Sum WithBot

open scoped Classical

universe u

namespace ConNF

/-!
The assumptions are as follows.

`S` and `T` are ordered supports, and we aim to produce an allowable permutation `ρ` such that
`ρ • S = T` under the hypothesis that `σ` specifies both `S` and `T`.
Note that this enforces that the set of indices in `μ` used in `S` and `T` agree.

We assume that `S` is a strong support, and that `T` is equivalent to a strong support `U`.
This condition will be relaxed later. The reordering `r` can be used to reinterpret the indices in
`T` in their "correct" positions in `U`.
-/

variable [Params.{u}] {α : Λ} [BasePositions] [FoaAssumptions α] {β : Iic α}
  {σ : Spec β} {S T U : OrdSupport β}
  (hσS : Specifies σ S) (hσT : Specifies σ T)
  {r : Tree Reorder β} (hr : OrdSupport.IsEquiv r U T)
  (hS : S.Strong) (hU: U.Strong)

namespace Spec

set_option pp.proofs.withType false

/-- Because `σ` specifies a strong support `S` as well as `T`, `T` must assign its atoms
at "atom times": their positions must be indexed by an atom. -/
theorem cpos_atom (A : ExtendedIndex β) (a : Atom) (ha : ⟨A, inl a⟩ ∈ T) :
    ∃ b, (T.cpos ⟨A, inl a⟩).get ha = inl b := by
  obtain ⟨⟨B, x⟩, hc₁, hc₂⟩ := hσS.exists_mem_of_dom _ (hσT.cpos_dom _ ha)
  rw [Prod.ext_iff] at hc₂
  cases hc₂.2
  simp only [hS.cpos_get_eq, and_true] at hc₂
  rw [hc₂]
  obtain (b | N) := x
  · exact ⟨b, rfl⟩
  exfalso
  have := hS.reduced_of_mem _ hc₁
  simp only [Reduced_iff, exists_false, inr.injEq, false_or] at this
  obtain ⟨L, rfl⟩ := this
  have hcT := hσT.atom_spec A a a.1.toNearLitter ha (hU.fst_toNearLitter_mem_equiv hr.equiv ha) rfl
  obtain (hL | ⟨⟨hL⟩⟩ | ⟨⟨hL⟩⟩) := flexible_cases' β A L
  · have hcS := hσS.flexible_spec A L.toNearLitter hc₁ hL
    simp_rw [hS.cpos_get_eq, ← hc₂, hcT] at hcS
  · have hcS := hσS.inflexibleBot_spec A L.toNearLitter hc₁ hL ?_
    · simp_rw [hS.cpos_get_eq, ← hc₂, hcT] at hcS
    · refine hS.transConstrains_mem _ _ (Reduced.mkAtom hL.a) (Relation.TransGen.single ?_) hc₁
      simp_rw [hL.hL, hL.path.hA]
      exact Constrains.fuzz_bot hL.path.hε _ hL.a
  · obtain ⟨_, _, _, hcS⟩ := hσS.inflexibleCoe_spec A L.toNearLitter hc₁ hL
    simp_rw [hS.cpos_get_eq, ← hc₂, hcT] at hcS

/-- Because `σ` specifies a strong support `S` as well as `T`, `T` must assign its near-litters
at "litter times": their positions must be indexed by a litter. -/
theorem cpos_nearLitter (A : ExtendedIndex β) (N : NearLitter) (hN : ⟨A, inr N⟩ ∈ T) :
    ∃ L : Litter, (T.cpos ⟨A, inr N⟩).get hN = inr L.toNearLitter := by
  obtain ⟨⟨B, x⟩, hc₁, hc₂⟩ := hσS.exists_mem_of_dom _ (hσT.cpos_dom _ hN)
  rw [Prod.ext_iff] at hc₂
  cases hc₂.2
  simp only [hS.cpos_get_eq, and_true] at hc₂
  rw [hc₂]
  obtain (b | N') := x
  swap
  · obtain ⟨L'⟩ := hS.isLitter_of_mem hc₁
    exact ⟨L', rfl⟩
  exfalso
  have hcS := hσS.atom_spec A b b.1.toNearLitter hc₁ (hS.fst_toNearLitter_mem hc₁) rfl
  have := hU.reduced_of_mem_equiv hr.equiv _ hN
  simp only [Reduced_iff, exists_false, inr.injEq, false_or] at this
  obtain ⟨L, rfl⟩ := this
  obtain (hL | ⟨⟨hL⟩⟩ | ⟨⟨hL⟩⟩) := flexible_cases' β A L
  · have hcT := hσT.flexible_spec A L.toNearLitter hN hL
    simp_rw [hS.cpos_get_eq, ← hc₂, hcT] at hcS
  · have hcT := hσT.inflexibleBot_spec A L.toNearLitter hN hL ?_
    · simp_rw [hS.cpos_get_eq, ← hc₂, hcT] at hcS
    · refine hU.transConstrains_mem_equiv hr.equiv _ _
        (Reduced.mkAtom hL.a) (Relation.TransGen.single ?_) hN
      simp_rw [hL.hL, hL.path.hA]
      exact Constrains.fuzz_bot hL.path.hε _ hL.a
  · obtain ⟨_, _, _, hcT⟩ := hσT.inflexibleCoe_spec A L.toNearLitter hN hL
    simp_rw [hS.cpos_get_eq, ← hc₂, hcT] at hcS

variable (T)

/-- Maps atoms in a strong support (in our case, `S`) to atoms in `T`
assigned the same position. -/
noncomputable def convertAtom (A : ExtendedIndex β) (a : Atom) : Part Atom :=
  ⟨∃ b : Atom, ∃ h : ⟨A, inl b⟩ ∈ T, (T.cpos ⟨A, inl b⟩).get h = inl a,
    Exists.choose⟩

/-- Maps litters in a strong support (in our case, `S`) to near-litters in `T`
assigned the same position. -/
noncomputable def convertLitter (A : ExtendedIndex β) (L : Litter) : Part NearLitter :=
  ⟨∃ N : NearLitter, ∃ h : ⟨A, inr N⟩ ∈ T, (T.cpos ⟨A, inr N⟩).get h = inr L.toNearLitter,
    Exists.choose⟩

/-- Maps atoms in a support `T` to the atom in a strong support in the same position. -/
noncomputable def deconvertAtom (A : ExtendedIndex β) (a : Atom) : Part Atom :=
  ⟨∃ b : Atom, ∃ h : ⟨A, inl a⟩ ∈ T, (T.cpos ⟨A, inl a⟩).get h = inl b,
    Exists.choose⟩

/-- Maps near-litters in a support `T` to the litter in a strong support in the same position. -/
noncomputable def deconvertLitter (A : ExtendedIndex β) (N : NearLitter) : Part Litter :=
  ⟨∃ L : Litter, ∃ h : ⟨A, inr N⟩ ∈ T, (T.cpos ⟨A, inr N⟩).get h = inr L.toNearLitter,
    Exists.choose⟩

variable {T}

theorem convertAtom_dom (A : ExtendedIndex β) (a : Atom) :
    (convertAtom T A a).Dom ↔ ⟨A, inl a⟩ ∈ S := by
  have := Specifies.dom_iff hσT ⟨inl a, A⟩
  rw [hσS.dom_iff ⟨inl a, A⟩] at this
  simp_rw [hS.cpos_get_eq] at this
  constructor
  · rintro ⟨b, hbT, h⟩
    obtain ⟨c, h₁, h₂⟩ := this.mpr ⟨_, hbT, Prod.ext h.symm rfl⟩
    suffices : c = ⟨A, inl a⟩
    · rwa [this] at h₁
    rw [Prod.ext_iff] at h₂
    exact SupportCondition.ext _ _ h₂.2.symm h₂.1.symm
  · intro h
    obtain ⟨c, h₁, h₂⟩ := this.mp ⟨_, h, rfl⟩
    rw [Prod.ext_iff] at h₂
    obtain ⟨A, b | N⟩ := c <;> cases h₂.2
    · exact ⟨b, h₁, h₂.1.symm⟩
    · obtain ⟨L, hL⟩ := cpos_nearLitter hσS hσT hr hS hU A N h₁
      rw [hL] at h₂
      simp only at h₂

theorem convertLitter_dom (A : ExtendedIndex β) (L : Litter) :
    (convertLitter T A L).Dom ↔ ⟨A, inr L.toNearLitter⟩ ∈ S := by
  have := Specifies.dom_iff hσT ⟨inr L.toNearLitter, A⟩
  rw [hσS.dom_iff ⟨inr L.toNearLitter, A⟩] at this
  simp_rw [hS.cpos_get_eq] at this
  constructor
  · rintro ⟨N, hNT, h⟩
    obtain ⟨c, h₁, h₂⟩ := this.mpr ⟨_, hNT, Prod.ext h.symm rfl⟩
    rw [Prod.ext_iff] at h₂
    obtain ⟨A, a | N'⟩ := c <;> cases h₂.2
    · cases h₂.1
    · cases h₂.1
      exact h₁
  · intro h
    obtain ⟨c, h₁, h₂⟩ := this.mp ⟨_, h, rfl⟩
    rw [Prod.ext_iff] at h₂
    obtain ⟨A, a | N'⟩ := c <;> cases h₂.2
    · obtain ⟨L, hL⟩ := cpos_atom hσS hσT hr hS hU A a h₁
      simp only [hL] at h₂
    · exact ⟨N', h₁, h₂.1.symm⟩

theorem deconvertAtom_dom (A : ExtendedIndex β) (a : Atom) :
    (deconvertAtom T A a).Dom ↔ ⟨A, inl a⟩ ∈ T := by
  have := Specifies.dom_iff hσT ⟨inl a, A⟩
  rw [hσS.dom_iff ⟨inl a, A⟩] at this
  simp_rw [hS.cpos_get_eq] at this
  constructor
  · rintro ⟨b, hbT, _⟩
    exact hbT
  · intro h
    obtain ⟨b, hb⟩ := cpos_atom hσS hσT hr hS hU A a h
    exact ⟨b, h, hb⟩

theorem deconvertLitter_dom (A : ExtendedIndex β) (N : NearLitter) :
    (deconvertLitter T A N).Dom ↔ ⟨A, inr N⟩ ∈ T := by
  have := Specifies.dom_iff hσT ⟨inr N, A⟩
  rw [hσS.dom_iff ⟨inr N, A⟩] at this
  simp_rw [hS.cpos_get_eq] at this
  constructor
  · rintro ⟨b, hbT, _⟩
    exact hbT
  · intro h
    obtain ⟨L, hL⟩ := cpos_nearLitter hσS hσT hr hS hU A N h
    exact ⟨L, h, hL⟩

theorem convertAtom_mem {A : ExtendedIndex β} {a : Atom} (h : (convertAtom T A a).Dom) :
    ⟨A, inl ((convertAtom T A a).get h)⟩ ∈ T :=
  h.choose_spec.1

theorem convertLitter_mem {A : ExtendedIndex β} {L : Litter} (h : (convertLitter T A L).Dom) :
    ⟨A, inr ((convertLitter T A L).get h)⟩ ∈ T :=
  h.choose_spec.1

theorem deconvertAtom_mem {A : ExtendedIndex β} {a : Atom} (h : (deconvertAtom T A a).Dom) :
    ⟨A, inl a⟩ ∈ T :=
  h.choose_spec.1

theorem deconvertLitter_mem {A : ExtendedIndex β} {N : NearLitter}
    (h : (deconvertLitter T A N).Dom) : ⟨A, inr N⟩ ∈ T :=
  h.choose_spec.1

theorem convertAtom_get {A : ExtendedIndex β} {a : Atom} (h : (convertAtom T A a).Dom) :
    (T.cpos ⟨A, inl ((convertAtom T A a).get h)⟩).get (convertAtom_mem h) = inl a :=
  h.choose_spec.2

theorem convertLitter_get {A : ExtendedIndex β} {L : Litter} (h : (convertLitter T A L).Dom) :
    (T.cpos ⟨A, inr ((convertLitter T A L).get h)⟩).get (convertLitter_mem h) = inr L.toNearLitter :=
  h.choose_spec.2

theorem get_deconvertAtom {A : ExtendedIndex β} {a : Atom} (h : (deconvertAtom T A a).Dom) :
    (T.cpos ⟨A, inl a⟩).get (deconvertAtom_mem h) = inl ((deconvertAtom T A a).get h) :=
  h.choose_spec.2

theorem get_deconvertLitter {A : ExtendedIndex β} {N : NearLitter}
    (h : (deconvertLitter T A N).Dom) :
    (T.cpos ⟨A, inr N⟩).get (deconvertLitter_mem h) =
      inr ((deconvertLitter T A N).get h).toNearLitter :=
  h.choose_spec.2

theorem convertLitter_isLitter {A : ExtendedIndex β} {L : Litter}
    (h : (convertLitter T A L).Dom) :
    ((convertLitter T A L).get h).IsLitter := by
  have := hU.reduced_of_mem_equiv hr.equiv _ (convertLitter_mem h)
  simp only [Reduced_iff, exists_false, inr.injEq, false_or] at this
  obtain ⟨L, h⟩ := this
  rw [h]
  exact NearLitter.IsLitter.mk _

theorem convertAtom_deconvertAtom_dom {A : ExtendedIndex β} {a : Atom}
    (h : (convertAtom T A a).Dom) :
    (deconvertAtom T A ((convertAtom T A a).get h)).Dom :=
  ⟨a, h.choose_spec⟩

theorem convertLitter_deconvertLitter_dom {A : ExtendedIndex β} {L : Litter}
    (h : (convertLitter T A L).Dom) :
    (deconvertLitter T A ((convertLitter T A L).get h)).Dom :=
  ⟨L, h.choose_spec⟩

theorem deconvertAtom_convertAtom_dom {A : ExtendedIndex β} {a : Atom}
    (h : (deconvertAtom T A a).Dom) :
    (convertAtom T A ((deconvertAtom T A a).get h)).Dom :=
  ⟨a, h.choose_spec⟩

theorem deconvertLitter_convertLitter_dom {A : ExtendedIndex β} {N : NearLitter}
    (h : (deconvertLitter T A N).Dom) :
    (convertLitter T A ((deconvertLitter T A N).get h)).Dom :=
  ⟨N, h.choose_spec⟩

theorem convertAtom_deconvertAtom {A : ExtendedIndex β} {a : Atom}
    (h : (convertAtom T A a).Dom) :
    (deconvertAtom T A ((convertAtom T A a).get h)).get (convertAtom_deconvertAtom_dom h) = a := by
  have := get_deconvertAtom (convertAtom_deconvertAtom_dom h)
  rw [convertAtom_get h, inl.injEq] at this
  exact this.symm

theorem convertLitter_deconvertLitter {A : ExtendedIndex β} {L : Litter}
    (h : (convertLitter T A L).Dom) :
    (deconvertLitter T A ((convertLitter T A L).get h)).get
      (convertLitter_deconvertLitter_dom h) = L := by
  have := get_deconvertLitter (convertLitter_deconvertLitter_dom h)
  rw [convertLitter_get h, inr.injEq, Litter.toNearLitter_injective.eq_iff] at this
  exact this.symm

theorem deconvertAtom_convertAtom {A : ExtendedIndex β} {a : Atom}
    (h : (deconvertAtom T A a).Dom) :
    (convertAtom T A ((deconvertAtom T A a).get h)).get (deconvertAtom_convertAtom_dom h) = a := by
  have := get_deconvertAtom h
  rw [← convertAtom_get (deconvertAtom_convertAtom_dom h)] at this
  have := T.injective _ _ _ _ (by rfl) this
  simp only [SupportCondition.mk.injEq, inl.injEq, true_and] at this
  exact this.symm

theorem deconvertLitter_convertLitter {A : ExtendedIndex β} {N : NearLitter}
    (h : (deconvertLitter T A N).Dom) :
    (convertLitter T A ((deconvertLitter T A N).get h)).get
      (deconvertLitter_convertLitter_dom h) = N := by
  have := get_deconvertLitter h
  rw [← convertLitter_get (deconvertLitter_convertLitter_dom h)] at this
  have := T.injective _ _ _ _ (by rfl) this
  simp only [SupportCondition.mk.injEq, inr.injEq, true_and] at this
  exact this.symm

theorem convertAtom_injective (A : ExtendedIndex β) (a b : Atom)
    (ha : (convertAtom T A a).Dom) (hb : (convertAtom T A b).Dom)
    (hab : (convertAtom T A a).get ha = (convertAtom T A b).get hb) :
    a = b := by
  rw [← convertAtom_deconvertAtom ha, ← convertAtom_deconvertAtom hb]
  simp_rw [hab]

theorem convertLitter_injective (A : ExtendedIndex β) (L₁ L₂ : Litter)
    (h₁ : (convertLitter T A L₁).Dom) (h₂ : (convertLitter T A L₂).Dom)
    (h : (convertLitter T A L₁).get h₁ = (convertLitter T A L₂).get h₂) :
    L₁ = L₂ := by
  rw [← convertLitter_deconvertLitter h₁, ← convertLitter_deconvertLitter h₂]
  simp_rw [h]

theorem convertLitter_injective' (A : ExtendedIndex β) (L₁ L₂ : Litter)
    (h₁ : (convertLitter T A L₁).Dom) (h₂ : (convertLitter T A L₂).Dom)
    (h : Set.Nonempty (((convertLitter T A L₁).get h₁ : Set Atom) ∩
      (convertLitter T A L₂).get h₂)) :
    L₁ = L₂ := by
  refine convertLitter_injective A L₁ L₂ h₁ h₂ ?_
  rw [(convertLitter_isLitter hr hU h₁).eq_fst_toNearLitter,
    (convertLitter_isLitter hr hU h₂).eq_fst_toNearLitter] at h ⊢
  obtain ⟨a, ha₁, ha₂⟩ := h
  refine congr_arg _ ?_
  exact ha₁.symm.trans ha₂

theorem convertAtom_ran (A : ExtendedIndex β) :
    PFun.ran (convertAtom T A) = PFun.Dom (deconvertAtom T A) := by
  ext a : 1
  constructor
  · intro ⟨b, hb₁, hb₂⟩
    subst hb₂
    refine ⟨(deconvertAtom T A ((convertAtom T A b).get hb₁)).get ?_, ?_, ?_⟩
    · exact convertAtom_deconvertAtom_dom hb₁
    · exact convertAtom_mem hb₁
    · rw [get_deconvertAtom]
  · intro ha
    refine ⟨(deconvertAtom T A a).get ha, ?_, ?_⟩
    · exact deconvertAtom_convertAtom_dom ha
    · rw [deconvertAtom_convertAtom]

theorem convertLitter_ran (A : ExtendedIndex β) :
    PFun.ran (convertLitter T A) = PFun.Dom (deconvertLitter T A) := by
  ext N : 1
  constructor
  · intro ⟨L, h₁, h₂⟩
    subst h₂
    refine ⟨(deconvertLitter T A ((convertLitter T A L).get h₁)).get ?_, ?_, ?_⟩
    · exact convertLitter_deconvertLitter_dom h₁
    · exact convertLitter_mem h₁
    · rw [get_deconvertLitter]
  · intro hN
    refine ⟨(deconvertLitter T A N).get hN, ?_, ?_⟩
    · exact deconvertLitter_convertLitter_dom hN
    · rw [deconvertLitter_convertLitter]

theorem deconvertAtom_ran (A : ExtendedIndex β) :
    PFun.ran (deconvertAtom T A) = PFun.Dom (convertAtom T A) := by
  ext a : 1
  constructor
  · intro ⟨b, hb₁, hb₂⟩
    subst hb₂
    refine ⟨(convertAtom T A ((deconvertAtom T A b).get hb₁)).get ?_, ?_, ?_⟩
    · exact deconvertAtom_convertAtom_dom hb₁
    · rw [deconvertAtom_dom hσS hσT hr hS hU] at hb₁
      rw [deconvertAtom_convertAtom]
      exact hb₁
    · rw [convertAtom_get]
  · intro ha
    refine ⟨(convertAtom T A a).get ha, ?_, ?_⟩
    · exact convertAtom_deconvertAtom_dom ha
    · rw [convertAtom_deconvertAtom]

theorem deconvertLitter_ran (A : ExtendedIndex β) :
    PFun.ran (deconvertLitter T A) = PFun.Dom (convertLitter T A) := by
  ext L : 1
  constructor
  · intro ⟨N, h₁, h₂⟩
    subst h₂
    refine ⟨(convertLitter T A ((deconvertLitter T A N).get h₁)).get ?_, ?_, ?_⟩
    · exact deconvertLitter_convertLitter_dom h₁
    · rw [deconvertLitter_dom hσS hσT hr hS hU] at h₁
      rw [deconvertLitter_convertLitter]
      exact h₁
    · rw [convertLitter_get]
  · intro hL
    refine ⟨(convertLitter T A L).get hL, ?_, ?_⟩
    · exact convertLitter_deconvertLitter_dom hL
    · rw [convertLitter_deconvertLitter]

theorem mem_convertAtom_ran (A : ExtendedIndex β) (a : Atom) (ha : ⟨A, inl a⟩ ∈ T) :
    a ∈ PFun.ran (convertAtom T A) := by
  rw [convertAtom_ran, PFun.Dom, mem_setOf, deconvertAtom_dom hσS hσT hr hS hU]
  exact ha

theorem mem_convertLitter_ran (A : ExtendedIndex β) (N : NearLitter) (hN : ⟨A, inr N⟩ ∈ T) :
    N ∈ PFun.ran (convertLitter T A) := by
  rw [convertLitter_ran, PFun.Dom, mem_setOf, deconvertLitter_dom hσS hσT hr hS hU]
  exact hN

theorem mem_deconvertAtom_ran (A : ExtendedIndex β) (a : Atom) (ha : ⟨A, inl a⟩ ∈ S) :
    a ∈ PFun.ran (deconvertAtom T A) := by
  rw [deconvertAtom_ran hσS hσT hr hS hU, PFun.Dom, mem_setOf, convertAtom_dom hσS hσT hr hS hU]
  exact ha

theorem mem_deconvertLitter_ran (A : ExtendedIndex β) (L : Litter)
    (hL : ⟨A, inr L.toNearLitter⟩ ∈ S) : L ∈ PFun.ran (deconvertLitter T A) := by
  rw [deconvertLitter_ran hσS hσT hr hS hU, PFun.Dom, mem_setOf, convertLitter_dom hσS hσT hr hS hU]
  exact hL

theorem convertAtom_dom_small (A : ExtendedIndex β) :
    Small (PFun.Dom (convertAtom T A)) := by
  change Small {a | (convertAtom T A a).Dom}
  simp only [convertAtom_dom hσS hσT hr hS hU A]
  refine S.dom_small.image_subset (fun a => ⟨A, inl a⟩) ?_ ?_
  · intros a b h
    cases h
    rfl
  · rintro _ ⟨a, h, rfl⟩
    exact h

theorem convertLitter_dom_small (A : ExtendedIndex β) :
    Small (PFun.Dom (convertLitter T A)) := by
  change Small {L | (convertLitter T A L).Dom}
  simp only [convertLitter_dom hσS hσT hr hS hU A]
  refine S.dom_small.image_subset (fun L => ⟨A, inr L.toNearLitter⟩) ?_ ?_
  · intros L₁ L₂ h
    cases h
    rfl
  · rintro _ ⟨L, h, rfl⟩
    exact h

/-- Convert atoms or litters in `S` to the equivalent atoms or litters in `T`. -/
noncomputable def convert : StructAction β :=
  fun A => {
    atomMap := convertAtom T A
    litterMap := convertLitter T A
    atomMap_dom_small := convertAtom_dom_small hσS hσT hr hS hU A
    litterMap_dom_small := convertLitter_dom_small hσS hσT hr hS hU A
  }

theorem convert_atomMap {A : ExtendedIndex β} :
    (convert hσS hσT hr hS hU A).atomMap = convertAtom T A :=
  rfl

theorem convert_litterMap {A : ExtendedIndex β} :
    (convert hσS hσT hr hS hU A).litterMap = convertLitter T A :=
  rfl

theorem _root_.ConNF.mem_toNearLitter {a : Atom} {L : Litter} :
    a ∈ L.toNearLitter ↔ a.1 = L :=
  Iff.rfl

theorem convertLitter_dom_of_convertAtom_dom {A : ExtendedIndex β} {a : Atom}
    (ha : (convertAtom T A a).Dom) : (convertLitter T A a.fst).Dom := by
  rw [convertLitter_dom hσS hσT hr hS hU]
  exact hS.transConstrains_mem _ _
    (Reduced.mkLitter _)
    (Relation.TransGen.single (Constrains.atom _ _))
    ((convertAtom_dom hσS hσT hr hS hU A a).mp ha)

theorem get_fst_eq_fst_get {A : ExtendedIndex β} {a : Atom} (ha : (convertAtom T A a).Dom) :
    (Part.get (convertAtom T A a) ha).fst =
    (Part.get (convertLitter T A a.fst)
      (convertLitter_dom_of_convertAtom_dom hσS hσT hr hS hU ha)).fst := by
  have haS := hσS.atom_spec A a a.1.toNearLitter
    ((convertAtom_dom hσS hσT hr hS hU A a).mp ha)
    (hS.fst_toNearLitter_mem ((convertAtom_dom hσS hσT hr hS hU A a).mp ha)) rfl
  have haT := hσT.atom_spec A ((convertAtom T A a).get ha)
    ((convertAtom T A a).get ha).1.toNearLitter
    (convertAtom_mem ha) (hU.fst_toNearLitter_mem_equiv hr.equiv (convertAtom_mem ha)) rfl
  simp_rw [hS.cpos_get_eq] at haS
  simp_rw [convertAtom_get ha] at haT
  rw [haS] at haT
  have := congr_arg Prod.fst (SpecCondition.atom_injective haT)
  have ha' : (convertLitter T A a.1).Dom
  · rw [convertLitter_dom hσS hσT hr hS hU]
    exact hS.transConstrains_mem _ _
      (Reduced.mkLitter _)
      (Relation.TransGen.single (Constrains.atom _ _))
      ((convertAtom_dom hσS hσT hr hS hU A a).mp ha)
  rw [← convertLitter_get ha'] at this
  have := T.injective _ _ _ _ (by rfl) this
  simp only [SupportCondition.mk.injEq, inr.injEq, true_and] at this
  exact (congr_arg Sigma.fst this).symm

theorem get_mem_get (A : ExtendedIndex β) (a : Atom) (ha : (convertAtom T A a).Dom)
    (L : Litter) (hL : (convertLitter T A L).Dom) :
    a.1 = L ↔ (convertAtom T A a).get ha ∈ (convertLitter T A L).get hL := by
  obtain hL' := (convertLitter_isLitter hr hU hL).eq_fst_toNearLitter
  rw [hL', mem_toNearLitter, get_fst_eq_fst_get hσS hσT hr hS hU ha]
  constructor
  · rintro rfl
    rfl
  · intro h
    exact convertLitter_injective' hr hU A _ _
      (convertLitter_dom_of_convertAtom_dom hσS hσT hr hS hU ha) hL
      (NearLitter.inter_nonempty_of_fst_eq_fst h)

theorem convert_lawful : StructAction.Lawful (convert hσS hσT hr hS hU) :=
  fun A => {
    atomMap_injective := convertAtom_injective A
    litterMap_injective := convertLitter_injective' hr hU A
    atom_mem := get_mem_get hσS hσT hr hS hU A
  }

theorem convert_mapFlexible : StructAction.MapFlexible (convert hσS hσT hr hS hU) := by
  intro A L hL₁ hL₂
  have hL₃ := hL₁
  rw [convert_litterMap, convertLitter_dom hσS hσT hr hS hU] at hL₃
  have hLS := hσS.flexible_spec A L.toNearLitter hL₃ hL₂
  simp_rw [hS.cpos_get_eq] at hLS
  obtain (hL | ⟨⟨hL⟩⟩ | ⟨⟨hL⟩⟩) := flexible_cases' β A ((convertLitter T A L).get hL₁).1
  · exact hL
  · exfalso
    have hLT := hσT.inflexibleBot_spec A _ (convertLitter_mem hL₁) hL ?_
    simp_rw [convertLitter_get] at hLT
    rw [hLS] at hLT
    · cases hLT
    · refine hU.transConstrains_mem_equiv hr.equiv _ _
        (Reduced.mkAtom hL.a) (Relation.TransGen.single ?_) (convertLitter_mem hL₁)
      have := Constrains.fuzz_bot hL.path.hε hL.path.B hL.a
      rw [← hL.hL, ← hL.path.hA,
        ← (convertLitter_isLitter hr hU hL₁).eq_fst_toNearLitter] at this
      exact this
  · exfalso
    obtain ⟨χ, _, _, hLT⟩ := hσT.inflexibleCoe_spec A _ (convertLitter_mem hL₁) hL
    simp_rw [convertLitter_get] at hLT
    rw [hLS] at hLT
    cases hLT

noncomputable def convertAllowable : Allowable β :=
  (StructApprox.freedom_of_action β
    (StructAction.rc (convert hσS hσT hr hS hU) (convert_lawful hσS hσT hr hS hU))
    (StructAction.rc_free _ _ (convert_mapFlexible hσS hσT hr hS hU))).choose

theorem convertAllowable_spec :
    (StructAction.rc (convert hσS hσT hr hS hU)
      (convert_lawful hσS hσT hr hS hU)).ExactlyApproximates
    (Allowable.toStructPerm (convertAllowable hσS hσT hr hS hU)) :=
  (StructApprox.freedom_of_action β
    (StructAction.rc (convert hσS hσT hr hS hU) (convert_lawful hσS hσT hr hS hU))
    (StructAction.rc_free _ _ (convert_mapFlexible hσS hσT hr hS hU))).choose_spec

theorem convertAllowable_smul_mem (c : SupportCondition β)
    (ih : ∀ (d : SupportCondition β), d <[α] c →
      (d ∈ S ↔ convertAllowable hσS hσT hr hS hU • d ∈ T) ∧
      ∀ (hdS : d ∈ S) (hdT : convertAllowable hσS hσT hr hS hU • d ∈ T),
        (S.cpos d).get hdS = (T.cpos (convertAllowable hσS hσT hr hS hU • d)).get hdT) :
    c ∈ S ↔ convertAllowable hσS hσT hr hS hU • c ∈ T := by
  obtain ⟨A, a | N⟩ := c
  · constructor
    · intro haS
      have ha : (convertAtom T A a).Dom
      · rw [convertAtom_dom hσS hσT hr hS hU]
        exact haS
      rw [Allowable.smul_supportCondition]
      dsimp only [smul_inl]
      rw [← (convertAllowable_spec hσS hσT hr hS hU A).map_atom a
          (Or.inl (Or.inl (Or.inl (Or.inl ha)))),
        StructAction.rc_smul_atom_eq (by exact ha)]
      simp_rw [convert_atomMap hσS hσT hr hS hU]
      exact convertAtom_mem ha
    · intro haT
      obtain ⟨b, hb₁, hb₂⟩ := mem_convertAtom_ran hσS hσT hr hS hU A _ haT
      simp only at hb₂
      have := (convertAllowable_spec hσS hσT hr hS hU A).map_atom b
        (Or.inl (Or.inl (Or.inl (Or.inl hb₁))))
      rw [StructAction.rc_smul_atom_eq] at this
      have := hb₂.symm.trans this
      rw [smul_left_cancel_iff] at this
      rw [this]
      rw [convertAtom_dom hσS hσT hr hS hU] at hb₁
      exact hb₁
  · sorry

theorem convertAllowable_smul_eq (c : SupportCondition β)
    (hcS : c ∈ S) (hcT : convertAllowable hσS hσT hr hS hU • c ∈ T)
    (ih : ∀ (d : SupportCondition β), d <[α] c →
      (d ∈ S ↔ convertAllowable hσS hσT hr hS hU • d ∈ T) ∧
      ∀ (hdS : d ∈ S) (hdT : convertAllowable hσS hσT hr hS hU • d ∈ T),
        (S.cpos d).get hdS = (T.cpos (convertAllowable hσS hσT hr hS hU • d)).get hdT) :
    (S.cpos c).get hcS = (T.cpos (convertAllowable hσS hσT hr hS hU • c)).get hcT := sorry

theorem convertAllowable_smul' (c : SupportCondition β) :
    (c ∈ S ↔ convertAllowable hσS hσT hr hS hU • c ∈ T) ∧
    (∀ hcS : c ∈ S, ∀ hcT : convertAllowable hσS hσT hr hS hU • c ∈ T,
      (S.cpos c).get hcS = (T.cpos ((convertAllowable hσS hσT hr hS hU) • c)).get hcT) := by
  refine (transConstrains_wf α β).induction
    (C := fun c => (c ∈ S ↔ convertAllowable hσS hσT hr hS hU • c ∈ T) ∧
      (∀ hcS : c ∈ S, ∀ hcT : convertAllowable hσS hσT hr hS hU • c ∈ T,
        (S.cpos c).get hcS = (T.cpos ((convertAllowable hσS hσT hr hS hU) • c)).get hcT))
    c ?_
  clear c
  intro c ih
  constructor
  · exact convertAllowable_smul_mem hσS hσT hr hS hU c ih
  · intro hcS hcT
    exact convertAllowable_smul_eq hσS hσT hr hS hU c hcS hcT ih

theorem convertAllowable_smul : convertAllowable hσS hσT hr hS hU • S = T := by
  refine OrdSupport.ext ?_ ?_
  · intro c
    have := (convertAllowable_smul' hσS hσT hr hS hU ((convertAllowable hσS hσT hr hS hU)⁻¹ • c)).1
    rw [smul_inv_smul] at this
    exact this
  · intro c
    have := (convertAllowable_smul' hσS hσT hr hS hU ((convertAllowable hσS hσT hr hS hU)⁻¹ • c)).2
    rw [smul_inv_smul] at this
    exact this

end Spec

end ConNF