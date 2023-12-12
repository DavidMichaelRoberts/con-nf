import Mathlib.Data.Prod.Lex
import ConNF.Fuzz
import ConNF.FOA.Basic.Hypotheses

/-!
# Constraints
Support conditions can be said to *constrain* each other in a number of ways.
This is detailed below. The `constrains` relation is well-founded.

## Main declarations
* `ConNF.Constrains`: The constrains relation.
* `ConNF.constrains_wf`: The constrains relation is well-founded.
* `ConNF.small_constrains`: Only a small amount of things are constrained by a particular support
    condition.
-/

open Quiver Set Sum WithBot

open scoped Cardinal Classical

universe u

namespace ConNF

variable [Params.{u}]

section ExtendedIndex

variable [BasePositions]

instance : Position (Atom ⊕ NearLitter) μ where
  pos := {
    toFun := fun x => match x with
      | inl a => pos a
      | inr N => pos N
    inj' := by
      rintro (a₁ | N₁) (a₂ | N₂) h
      · exact congr_arg _ (pos_injective h)
      · cases pos_atom_ne_pos_nearLitter a₁ N₂ h
      · cases pos_atom_ne_pos_nearLitter a₂ N₁ h.symm
      · exact congr_arg _ (pos_injective h)
  }

/-- Override the default instance for `LT (α ⊕ β)`. -/
@[default_instance 1500]
instance : LT (Atom ⊕ NearLitter) :=
  ⟨InvImage (· < ·) pos⟩

@[simp]
theorem pos_atomNearLitter_inl (a : Atom) :
    pos (inl a : Atom ⊕ NearLitter) = pos a :=
  rfl

@[simp]
theorem pos_atomNearLitter_inr (N : NearLitter) :
    pos (inr N : Atom ⊕ NearLitter) = pos N :=
  rfl

end ExtendedIndex

variable [BasePositions] [Level] [FOAAssumptions] {β : Λ}

/-- Support conditions can be said to *constrain* each other in a number of ways.
1. `(L, A) ≺ (a, A)` when `a ∈ L` and `L` is a litter. We can say that an atom is constrained by the
    litter it belongs to.
2. `(N°, A) ≺ (N, A)` when `N` is a near-litter not equal to its corresponding litter `N°`.
3. `(a, A) ≺ (N, A)` for all `a ∈ N ∆ N°`.
4. `(x, A ≫ (γ ⟶ δ) ≫ B) ≺ (f_{γ,δ}(t), A ≫ (γ ⟶ ε) ≫ (ε ⟶ ⊥))` for all paths `A : β ⟶ γ` and
    `δ, ε < γ` with `δ ≠ ε`, `t ∈ τ_γ`, where `(x, B)` lies in the designated `δ`-support of `t`.
-/
@[mk_iff]
inductive Constrains : SupportCondition β → SupportCondition β → Prop
  | atom (A : ExtendedIndex β) (a : Atom) : Constrains ⟨A, inr a.1.toNearLitter⟩ ⟨A, inl a⟩
  | nearLitter (A : ExtendedIndex β) (N : NearLitter) (hN : ¬N.IsLitter) :
    Constrains ⟨A, inr N.fst.toNearLitter⟩ ⟨A, inr N⟩
  | symmDiff (A : ExtendedIndex β) (N : NearLitter) (a : Atom) :
    a ∈ litterSet N.fst ∆ N.snd → Constrains ⟨A, inl a⟩ ⟨A, inr N⟩
  | fuzz ⦃γ : Λ⦄ [LeLevel γ] ⦃δ : Λ⦄ [LtLevel δ] ⦃ε : Λ⦄ [LtLevel ε]
    (hδ : (δ : TypeIndex) < γ) (hε : (ε : TypeIndex) < γ) (hδε : (δ : TypeIndex) ≠ ε)
    (A : Path (β : TypeIndex) γ) (t : Tangle δ) (c : SupportCondition δ) :
    c ∈ designatedSupport t →
    Constrains ⟨(A.cons hδ).comp c.path, c.value⟩
      ⟨(A.cons hε).cons (bot_lt_coe _), inr (fuzz hδε t).toNearLitter⟩
  | fuzz_bot ⦃γ : Λ⦄ [LeLevel γ] ⦃ε : Λ⦄ [LtLevel ε]
    (hε : (ε : TypeIndex) < γ) (A : Path (β : TypeIndex) γ) (a : Atom) :
    Constrains ⟨A.cons (bot_lt_coe _), inl a⟩
      ⟨(A.cons hε).cons (bot_lt_coe _), inr (fuzz (bot_ne_coe (a := ε)) a).toNearLitter⟩

/-! We declare new notation for the "constrains" relation on support conditions. -/

@[inherit_doc] infix:50 " ≺ " => Constrains

theorem constrains_subrelation : Subrelation
    ((· ≺ ·) : SupportCondition β → _ → Prop)
    (InvImage (· < ·) SupportCondition.value) := by
  intro c d h
  obtain ⟨A, a⟩ | ⟨A, N, hN⟩ | ⟨A, N, a, ha⟩ | ⟨hδ, hε, hδε, A, t, c, hc⟩ | ⟨hδ, A, a⟩ := h
  · exact litter_lt_atom a.1 a rfl
  · exact litter_lt_nearLitter N hN
  · exact symmDiff_lt_nearLitter N a ha
  · have := fuzz_pos hδε t ?_ ?_
    rw [PositionedTypedObjects.pos_nearLitter_eq] at this
    refine' lt_of_le_of_lt _ this
    obtain ⟨B, a | N⟩ := c
    · exact PositionedTypedObjects.pos_atom_le t B a hc
    · exact PositionedTypedObjects.pos_nearLitter_le t B N hc
    · rfl
  · simp only [InvImage, elim_inr]
    convert pos_atom_lt_fuzz a
    simp only [← pos_lt_pos, pos_atomNearLitter_inl, pos_atomNearLitter_inr]
    rw [@PositionedTypedObjects.pos_nearLitter_eq _ _ _ ?_ ?_ ?_ ?_ _]
    infer_instance

/-- The `≺` relation is well-founded. By the conditions on orderings, if we have `(x, A) ≺ (y, B)`,
then `x < y` in `µ`, under the `typedNearLitter` or `typedAtom` maps. -/
theorem constrains_wf (β : Λ) : WellFounded ((· ≺ · ) : SupportCondition β → _ → Prop) :=
  Subrelation.wf constrains_subrelation IsWellFounded.wf

@[simp]
theorem constrains_atom {c : SupportCondition β} {A : ExtendedIndex β} {a : Atom} :
    c ≺ ⟨A, inl a⟩ ↔ c = ⟨A, inr a.1.toNearLitter⟩ := by
  constructor
  · rintro ⟨⟩
    rfl
  · rintro rfl
    exact Constrains.atom A a

/-- The constrains relation is stable under composition of paths. -/
theorem constrains_comp {β γ : Λ} {c d : SupportCondition γ} (h : c ≺ d)
    (B : Path (β : TypeIndex) γ) : ⟨B.comp c.path, c.value⟩ ≺ ⟨B.comp d.path, d.value⟩ := by
  obtain ⟨A, a⟩ | ⟨A, N, hN⟩ | ⟨A, N, a, ha⟩ | ⟨hδ, hε, hδε, A, t, c, hc⟩ | ⟨hδ, A, a⟩ := h
  · exact Constrains.atom _ _
  · exact Constrains.nearLitter _ _ hN
  · exact Constrains.symmDiff _ _ _ ha
  · rw [Path.comp_cons, ← Path.comp_assoc, Path.comp_cons]
    exact Constrains.fuzz hδ hε hδε (B.comp A) t c hc
  · rw [Path.comp_cons]
    exact Constrains.fuzz_bot hδ (B.comp A) a

instance : PartialOrder (SupportCondition β) where
  le := Relation.ReflTransGen (· ≺ ·)
  lt := Relation.TransGen (· ≺ ·)
  le_refl := fun _ => Relation.ReflTransGen.refl
  le_trans := fun _ _ _ => Relation.ReflTransGen.trans
  lt_iff_le_not_le := by
    intro c d
    constructor
    · intro h
      exact ⟨h.to_reflTransGen,
        fun h' => (constrains_wf β).transGen.isIrrefl.irrefl d (h.trans_right h')⟩
    · intro h
      obtain (rfl | h') := Relation.reflTransGen_iff_eq_or_transGen.mp h.1
      · cases h.2 Relation.ReflTransGen.refl
      · exact h'
  le_antisymm := by
    intro c d h₁ h₂
    obtain (h₁ | h₁) := Relation.reflTransGen_iff_eq_or_transGen.mp h₁
    · exact h₁.symm
    obtain (h₂ | h₂) := Relation.reflTransGen_iff_eq_or_transGen.mp h₂
    · exact h₂
    cases (constrains_wf β).transGen.isIrrefl.irrefl c (h₁.trans h₂)

theorem lt_subrelation : Subrelation
    ((· < ·) : SupportCondition β → _ → Prop)
    (InvImage (· < ·) SupportCondition.value) := by
  intro c d h
  change pos c.value < pos d.value
  induction h with
  | single hcd => exact constrains_subrelation hcd
  | tail _ h ih => exact ih.trans (constrains_subrelation h)

instance : WellFoundedLT (SupportCondition β) where
  wf := (constrains_wf β).transGen

instance : WellFoundedRelation (SupportCondition β) :=
  ⟨(· < ·), (constrains_wf β).transGen⟩

theorem SupportCondition.le_iff {c d : SupportCondition β} :
    c ≤ d ↔ Relation.ReflTransGen (· ≺ ·) c d :=
  Iff.rfl

theorem SupportCondition.lt_iff {c d : SupportCondition β} :
    c < d ↔ Relation.TransGen (· ≺ ·) c d :=
  Iff.rfl

theorem le_comp {β γ : Λ} {c d : SupportCondition γ} (h : c ≤ d)
    (B : Path (β : TypeIndex) γ) :
    (⟨B.comp c.path, c.value⟩ : SupportCondition β) ≤ ⟨B.comp d.path, d.value⟩ := by
  induction h with
  | refl => exact Relation.ReflTransGen.refl
  | tail _ h ih => exact Relation.ReflTransGen.tail ih (constrains_comp h B)

theorem lt_comp {β γ : Λ} {c d : SupportCondition γ} (h : c < d)
    (B : Path (β : TypeIndex) γ) :
    (⟨B.comp c.path, c.value⟩ : SupportCondition β) < ⟨B.comp d.path, d.value⟩ := by
  induction h with
  | single h => exact Relation.TransGen.single (constrains_comp h B)
  | tail _ h ih => exact Relation.TransGen.tail ih (constrains_comp h B)

theorem le_nearLitter {β : Λ} {N : NearLitter} {B : ExtendedIndex β}
    {c : SupportCondition β} (h : ⟨B, inr N⟩ ≤ c) : ⟨B, inr N.1.toNearLitter⟩ ≤ c := by
  by_cases h' : N.IsLitter
  · obtain ⟨L, rfl⟩ := h'.exists_litter_eq
    exact h
  · exact Relation.ReflTransGen.head (Constrains.nearLitter B N h') h

theorem lt_nearLitter {β : Λ} {N : NearLitter} {B : ExtendedIndex β}
    {c : SupportCondition β} (h : c < ⟨B, inr N.1.toNearLitter⟩) : c < ⟨B, inr N⟩ := by
  by_cases h' : N.IsLitter
  · obtain ⟨L, rfl⟩ := h'.exists_litter_eq
    exact h
  · exact Relation.TransGen.tail h (Constrains.nearLitter B N h')

theorem lt_nearLitter' {β : Λ} {N : NearLitter} {B : ExtendedIndex β}
    {c : SupportCondition β} (h : ⟨B, inr N⟩ < c) : ⟨B, inr N.1.toNearLitter⟩ < c := by
  by_cases h' : N.IsLitter
  · obtain ⟨L, rfl⟩ := h'.exists_litter_eq
    exact h
  · exact Relation.TransGen.head (Constrains.nearLitter B N h') h

theorem small_constrains {β : Λ} (c : SupportCondition β) : Small {d | d ≺ c} := by
  obtain ⟨A, a | N⟩ := c
  · simp only [constrains_atom, setOf_eq_eq_singleton, small_singleton]
  simp_rw [Constrains_iff]
  refine Small.union ?_ (Small.union ?_ (Small.union ?_ (Small.union ?_ ?_))) <;>
    rw [small_setOf]
  · change Small {c | ∃ b B, _ ∧ _ = _}
    simp only [SupportCondition.mk.injEq, false_and, and_false, exists_false,
      setOf_false, small_empty]
  · change Small {c | ∃ B N', _}
    refine Set.Subsingleton.small ?_
    rintro c ⟨_, _, _, ⟨rfl, rfl⟩, h₁⟩ d ⟨_, _, _, ⟨rfl, rfl⟩, h₂⟩
    cases h₁
    cases h₂
    rfl
  · change Small {c | ∃ B N' a, _}
    convert (show Small (litterSet N.fst ∆ N) from N.2.prop).image
      (f := fun a : Atom => (⟨A, inl a⟩ : SupportCondition β)) using 1
    ext c : 1
    simp only [mem_setOf_eq, mem_image]
    constructor
    · rintro ⟨B, N', a, h₁, h₂, h₃⟩
      cases h₃
      exact ⟨a, h₁, h₂.symm⟩
    · rintro ⟨a, h₁, h₂⟩
      exact ⟨A, N, a, h₁, h₂.symm, rfl⟩
  · by_cases h :
      ∃ (γ : Λ) (_ : LeLevel γ) (δ : Λ) (_ : LtLevel δ) (ε : Λ) (_ : LtLevel ε)
        (_ : (δ : TypeIndex) < γ) (hε : (ε : TypeIndex) < γ) (hδε : (δ : TypeIndex) ≠ ε)
        (B : Path (β : TypeIndex) γ) (t : Tangle δ),
        N = (fuzz hδε t).toNearLitter ∧ A = (B.cons hε).cons (bot_lt_coe _)
    · obtain ⟨γ, _, δ, _, ε, _, hδ, hε, hδε, B, t, rfl, rfl⟩ := h
      refine lt_of_le_of_lt ?_ (designatedSupport t).small
      suffices
        #{a : SupportCondition β |
            ∃ c : designatedSupport t, a = ⟨(B.cons hδ).comp c.val.path, c.val.value⟩} ≤
          #(designatedSupport t) by
        refine le_trans (Cardinal.mk_subtype_le_of_subset ?_) this
        rintro x ⟨_, _, _, _, _, _, _, _, _, _, _, c, hc, rfl, h⟩
        rw [SupportCondition.mk.injEq] at h
        simp only [inr.injEq, Litter.toNearLitter_injective.eq_iff] at h
        cases WithBot.coe_injective (fuzz_congr_β h.2)
        cases fuzz_congr_γ h.2
        cases fuzz_injective _ h.2
        cases coe_inj.mp (Path.obj_eq_of_cons_eq_cons (Path.heq_of_cons_eq_cons h.1).eq)
        cases (Path.heq_of_cons_eq_cons (Path.heq_of_cons_eq_cons h.1).eq).eq
        exact ⟨⟨c, hc⟩, rfl⟩
      refine ⟨⟨fun a => a.prop.choose, ?_⟩⟩
      intro a b h
      refine Subtype.coe_inj.mp ?_
      rw [a.prop.choose_spec, b.prop.choose_spec]
      simp only [h]
    · refine small_of_forall_not_mem ?_
      rintro x ⟨γ, _, δ, _, ε, _, hδ, hε, hδε, B, t, c, _, rfl, hA⟩
      rw [SupportCondition.mk.injEq] at hA
      simp only [inr.injEq] at hA
      exact h ⟨γ, inferInstance, δ, inferInstance, ε, inferInstance, hδ, hε, hδε, B, t, hA.2, hA.1⟩
  · refine Set.Subsingleton.small ?_
    rintro ⟨c, C⟩ ⟨γ, _, ε, _, hε, C', a, hc₁, hc₂⟩ ⟨d, D⟩ ⟨γ, _, ε, _, hε, D', b, hd₁, hd₂⟩
    rw [SupportCondition.mk.injEq] at hc₁ hc₂ hd₁ hd₂
    simp only [inr.injEq] at hc₂ hd₂
    rw [hc₁.1, hc₁.2, hd₁.1, hd₁.2]
    rw [hc₂.1, hc₂.2, Litter.toNearLitter_injective.eq_iff] at hd₂
    cases coe_inj.mp (Path.obj_eq_of_cons_eq_cons hd₂.1)
    cases coe_inj.mp (Path.obj_eq_of_cons_eq_cons (Path.heq_of_cons_eq_cons hd₂.1).eq)
    cases (Path.heq_of_cons_eq_cons (Path.heq_of_cons_eq_cons hd₂.1).eq).eq
    rw [(fuzz_injective bot_ne_coe).eq_iff] at hd₂
    cases hd₂.2
    rfl

end ConNF