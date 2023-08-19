import ConNF.Phase1.AMap

/-!
# Equivalence of codes

Several codes will be identified to make one TTT object. A TTT object has extensions for all type
indices (except possibly `⊥`), so our equivalence classes must too.

One way to do this is to make an equivalence class out of a code and its image under each A-map.
Thus we want to partition the big tree given by `aMap_rel` into trees of height `1` that each
contains all descendents of its root (this is a slight lie for empty codes as the one equivalence
class they form won't be a tree but rather a complete graph).

This is where code parity kicks in. We recursively pick out the small trees by noticing that codes
whose preimages under A-maps are all in a small tree already (in particular, those that have no
preimage under an A-map) must be the root of their own small tree, and that codes that are a
image of some root of a small tree must belong to that same tree. This motivates the following
definitions:
* A code is even if all its preimages under A-maps are odd.
* A code is odd if one of its preimages under A-maps are even.

If we replace "even" and "odd" by "winning" and "losing", we precisely get the rules for determining
whether a game position is winning or losing.

Note that for nonempty codes there is at most one preimage under A-maps.

## Main declarations

* `con_nf.is_even`, `con_nf.is_odd`: Code parity.
* `con_nf.code.equiv`: Equivalence of codes.
-/

open Set WithBot

universe u

namespace ConNF

variable [Params.{u}] [PositionData] {α : Λ} {β : IioBot α} {γ : Iio α} [CoreTangleCumul α]
  [AlmostTangleCumul α] [PositionedTangleCumul α]

open IioBot

namespace Code

variable {c d : Code α}

/-! ### Parity of a code

Parity of codes. We define them mutually inductively (`even_odd ff` is evenness, `even_odd tt`
is oddity). If we consider codes as states of a game and `aMap_rel` as the "leads to"
relation, then even codes are precisely losing codes and odd codes are precisely winning codes.
Parity of a nonempty code corresponds to the parity of its number of iterated preimages under
A-maps. The only even empty code is `⊥` one, all others are odd.
-/

mutual
/-- A code is even iff it only leads to odd codes. -/
  @[mk_iff]
  inductive IsEven : Code α → Prop
    | intro : ∀ c, (∀ d, d ↝ c → IsOdd d) → IsEven c

  /-- A code is odd iff it leads to some even code. -/
  @[mk_iff]
  inductive IsOdd : Code α → Prop
    | intro : ∀ c d, d ↝ c → IsEven d → IsOdd c
end

theorem isEven_of_forall_not (h : ∀ d, ¬d ↝ c) : IsEven c :=
  (IsEven_iff c).2 fun _ hd => (h _ hd).elim

@[simp]
theorem isEven_of_eq_bot (c : Code α) (hc : c.1.1 = ⊥) : c.IsEven :=
  isEven_of_forall_not <| by rintro d ⟨β, -⟩; exact coe_ne_bot hc

@[simp]
theorem isEven_bot (s : Set Atom) : IsEven (mk ⊥ s : Code α) :=
  isEven_of_eq_bot _ rfl

theorem not_isOdd_bot (s : Set Atom) : ¬IsOdd (mk ⊥ s : Code α) := by
  simp_rw [IsOdd_iff, AMapRel_iff]
  rintro ⟨d, ⟨γ, _, h⟩, _⟩
  exact bot_ne_mk_coe (congr_arg Sigma.fst h)

@[simp]
theorem IsEmpty.isEven_iff (hc : c.IsEmpty) : IsEven c ↔ (c.1 : TypeIndex) = ⊥ := by
  refine ⟨?_, isEven_of_eq_bot _⟩
  intro h
  obtain ⟨⟨_ | β, hβ⟩, s⟩ := c
  · rfl
  · simp [Code.IsEmpty] at hc
    cases hc
    have := not_isOdd_bot ∅ ((IsEven_iff _).1 h ⟨⟨⊥, _⟩, ∅⟩ ?_)
    · cases this
    convert AMapRel.intro ⟨β, coe_lt_coe.1 hβ⟩ _
    · rw [aMapCode_ne]
      refine Sigma.ext rfl (heq_of_eq ?_)
      swap
      · simp only [ne_eq, Subtype.mk.injEq, WithBot.bot_ne_coe, not_false_eq_true]
      rw [snd_mk]
      exact aMap_empty.symm
    · simp only [ne_eq, Subtype.mk.injEq, WithBot.bot_ne_coe, not_false_eq_true]

@[simp]
theorem IsEmpty.isOdd_iff (hc : c.IsEmpty) : IsOdd c ↔ (c.1 : TypeIndex) ≠ ⊥ :=
  by
  obtain ⟨⟨β, hβ⟩, s⟩ := c
  refine' ⟨_, fun h => (IsOdd_iff _).2 ⟨mk ⊥ ∅, _, isEven_bot _⟩⟩
  · rintro h (rfl : β = _)
    exact not_isOdd_bot _ h
  · lift β to Λ using h
    refine (AMapRel_iff _ _).2 ⟨⟨β, coe_lt_coe.1 hβ⟩, bot_ne_mk_coe, ?_⟩
    simp only [ne_eq, bot_ne_mk_coe, not_false_eq_true, aMapCode_mk_ne, aMap_empty]
    exact Sigma.ext rfl (heq_of_eq hc.eq)

@[simp]
theorem isEven_empty_iff : IsEven (mk β ∅) ↔ (β : TypeIndex) = ⊥ :=
  IsEmpty.isEven_iff rfl

@[simp]
theorem isOdd_empty_iff : IsOdd (mk β ∅) ↔ (β : TypeIndex) ≠ ⊥ :=
  IsEmpty.isOdd_iff rfl

private theorem not_isOdd_nonempty : ∀ c : NonemptyCode α, ¬c.1.IsOdd ↔ c.1.IsEven
  | c => by
    rw [IsOdd_iff, IsEven_iff]
    push_neg
    apply forall_congr' _
    intro d
    apply imp_congr_right _
    intro h
    rw [Iff.comm, ← not_iff_not, Classical.not_not]
    obtain hd | hd := d.2.eq_empty_or_nonempty
    · rw [IsEmpty.isOdd_iff hd, IsEmpty.isEven_iff hd, Classical.not_not]
    · let _ : AMapRel' ⟨d, hd⟩ c := aMapRel_coe_coe.1 h
      exact not_isOdd_nonempty ⟨d, hd⟩
termination_by not_isOdd_nonempty c => c

@[simp]
theorem not_isOdd : ¬c.IsOdd ↔ c.IsEven :=
  by
  obtain hc | hc := c.2.eq_empty_or_nonempty
  · rw [IsEmpty.isOdd_iff hc, IsEmpty.isEven_iff hc, Classical.not_not]
  · exact not_isOdd_nonempty ⟨c, hc⟩

@[simp]
theorem not_isEven : ¬c.IsEven ↔ c.IsOdd :=
  not_isOdd.symm.not_left

alias not_isOdd ↔ _ IsEven.not_isOdd

alias not_isEven ↔ _ IsOdd.not_isEven

theorem isEven_or_isOdd (c : Code α) : c.IsEven ∨ c.IsOdd := by rw [← not_isEven]; exact em _

protected theorem _root_.ConNF.AMapRel.isOdd (hc : c.IsEven) (h : c ↝ d) : d.IsOdd :=
  (IsOdd_iff d).2 ⟨_, h, hc⟩

protected theorem IsEven.aMapCode (hc : c.IsEven) (hcγ : c.1 ≠ γ) : (aMapCode γ c).IsOdd :=
  (AMapRel.intro _ hcγ).isOdd hc

protected theorem IsOdd.aMapCode (hc : c.IsOdd) (hc' : c.2.Nonempty) (hcγ : c.1 ≠ γ) :
    (aMapCode γ c).IsEven :=
  (IsEven_iff _).2 fun d hd => by rwa [(aMapRel_aMapCode _ hc' hcγ).1 hd]

protected theorem IsEven.aMapCode_ne (hc : c.IsEven) (hd : d.IsEven) (hcγ : c.1 ≠ γ) :
    aMapCode γ c ≠ d := by rintro rfl; exact hd.not_isOdd (hc.aMapCode hcγ)

theorem aMapCode_ne_bot {s} : aMapCode γ c ≠ mk ⊥ s :=
  ne_of_apply_ne (Subtype.val ∘ Sigma.fst) coe_ne_bot

theorem aMapCode_ne_singleton {t} (hcβ : c.1 ≠ β) : aMapCode γ c ≠ mk β {t} := by
  intro h
  rw [aMapCode, mk, Sigma.ext_iff] at h
  simp only [ne_eq] at h
  obtain ⟨rfl, h⟩ := h
  -- have := eq_of_heq h
  refine' (Cardinal.one_lt_aleph0.trans_le <| κ_regular.aleph0_le.trans κ_le_μ).not_le _
  rw [← Cardinal.mk_singleton t, ← h.eq]
  refine' μ_le_mk_aMapCode c hcβ (aMapCode_nonempty.1 _)
  exact γ
  rw [aMapCode, eq_of_heq h]
  simp only [snd_mk, singleton_nonempty]

@[simp]
theorem isEven_singleton (t) : (mk β {t}).IsEven := by
  refine' isEven_of_forall_not fun c hc => _
  obtain ⟨γ, hc', h⟩ := (AMapRel_iff _ _).1 hc
  have := congr_arg Sigma.fst h
  cases this
  exact aMapCode_ne_singleton hc' h.symm

/-! ### Equivalence of codes -/

/-- Equivalence of codes. -/
@[mk_iff]
inductive Equiv : Code α → Code α → Prop
  | refl (c) : Equiv c c
  | aMap_left (c : Code α) (hc : c.IsEven) (β : Iio α) (hcβ : c.1 ≠ β) : Equiv (aMapCode β c) c
  | aMap_right (c : Code α) (hc : c.IsEven) (β : Iio α) (hcβ : c.1 ≠ β) : Equiv c (aMapCode β c)
  | aMap_aMap (c : Code α) (hc : c.IsEven) (β : Iio α) (hcβ : c.1 ≠ β) (γ : Iio α) (hcγ : c.1 ≠ γ) :
    Equiv (aMapCode β c) (aMapCode γ c)

/-! We declare new notation for code equivalence. -/

infixl:50 " ≡ " => Equiv

namespace Equiv

attribute [refl] refl

protected theorem rfl : c ≡ c :=
  refl _

theorem of_eq : c = d → c ≡ d := by rintro rfl; rfl

theorem symm : Symmetric ((· ≡ ·) : Code α → Code α → Prop)
  | _, _, refl _ => refl _
  | _, _, aMap_left c β hc hcβ => aMap_right c β hc hcβ
  | _, _, aMap_right c β hc hcβ => aMap_left c β hc hcβ
  | _, _, aMap_aMap c hc β hcβ γ hcγ => aMap_aMap c hc γ hcγ β hcβ

theorem comm : c ≡ d ↔ d ≡ c :=
  symm.iff _ _

theorem empty_empty : ∀ β γ, (⟨β, ∅⟩ : Code α) ≡ ⟨γ, ∅⟩
  | ⟨⊥, _⟩, ⟨⊥, _⟩ => Equiv.rfl
  | ⟨⊥, _⟩, ⟨(γ : Λ), hγ⟩ => by
    convert aMap_right _ (isEven_bot _) ⟨_, coe_lt_coe.1 hγ⟩ bot_ne_mk_coe
    rw [aMapCode, extension_ne _ _ bot_ne_coe, snd_mk, aMap_empty]
    rfl
  | ⟨(β : Λ), hβ⟩, ⟨⊥, _⟩ => by
    convert aMap_left _ (isEven_bot _) ⟨_, coe_lt_coe.1 hβ⟩ bot_ne_mk_coe
    rw [aMapCode, extension_ne _ _ bot_ne_coe, snd_mk, aMap_empty]
    rfl
  | ⟨(β : Λ), hβ⟩, ⟨(γ : Λ), hγ⟩ => by
    convert
        aMap_aMap _ (isEven_bot ∅) ⟨_, coe_lt_coe.1 hβ⟩ bot_ne_mk_coe ⟨_, coe_lt_coe.1 hγ⟩
          bot_ne_mk_coe <;>
    · rw [aMapCode, extension_ne _ _ bot_ne_coe, snd_mk, aMap_empty]
      rfl

protected theorem _root_.ConNF.Code.IsEmpty.equiv (hc : c.IsEmpty) (hd : d.IsEmpty) : c ≡ d := by
  obtain ⟨γ, c⟩ := c
  obtain ⟨δ, d⟩ := d
  change c = ∅ at hc
  change d = ∅ at hd
  subst hc
  subst hd
  exact empty_empty _ _

theorem trans {c d e : Code α} : c ≡ d → d ≡ e → c ≡ e := by
  rw [Equiv_iff, Equiv_iff]
  rintro (rfl | ⟨hc, β, hcβ, rfl⟩ | ⟨hc, β, hcβ, rfl⟩ | ⟨d, hd, γ, hdγ, ε, hdε, rfl, rfl⟩)
  · exact (Equiv_iff _ _).2
  · rintro (rfl | ⟨hc', γ, hcγ, rfl⟩ | ⟨-, γ, hcγ, rfl⟩ | ⟨_, hc', γ, hcγ, ε, _, rfl, rfl⟩)
    · exact aMap_left _ hc β hcβ
    · cases (hc'.aMapCode hcγ).not_isEven hc
    · exact aMap_aMap _ hc _ hcβ _ hcγ
    · cases (hc'.aMapCode hcγ).not_isEven hc
  · rintro (rfl | ⟨_, γ, hcγ, hce⟩ | ⟨hc', γ, _, rfl⟩ | ⟨e, he, γ, hcγ, ε, heε, hce, rfl⟩)
    · exact aMap_right _ hc β hcβ
    · obtain h | h := c.2.eq_empty_or_nonempty
      · refine' IsEmpty.equiv h _
        rwa [← aMapCode_isEmpty, ← hce, aMapCode_isEmpty, Code.IsEmpty]
      · exact of_eq (eq_of_aMapCode h hcβ hcγ hce)
    · cases (hc.aMapCode hcβ).not_isEven hc'
    · obtain h | h := c.2.eq_empty_or_nonempty
      · refine' IsEmpty.equiv h _
        rwa [aMapCode_isEmpty, ← aMapCode_isEmpty, ← hce, aMapCode_isEmpty, Code.IsEmpty]
      · rw [eq_of_aMapCode h hcβ hcγ hce]
        exact aMap_right _ he _ heε
  · rintro (rfl | ⟨_, γ, heγ, hde⟩ | ⟨hd', γ, -, rfl⟩ | ⟨e, he, ι, heι, κ, heκ, hde, rfl⟩)
    · exact aMap_aMap _ hd _ hdγ _ hdε
    · obtain h | h := e.2.eq_empty_or_nonempty
      · refine' IsEmpty.equiv _ h
        rwa [aMapCode_isEmpty, ← aMapCode_isEmpty, hde, aMapCode_isEmpty, Code.IsEmpty]
      · rw [eq_of_aMapCode h heγ hdε hde.symm]
        exact aMap_left _ hd _ hdγ
    · cases (hd.aMapCode hdε).not_isEven hd'
    · obtain h | h := d.2.eq_empty_or_nonempty
      · refine' (IsEmpty.aMapCode h).equiv _
        rwa [aMapCode_isEmpty, ← aMapCode_isEmpty, ← hde, aMapCode_isEmpty, Code.IsEmpty]
      · have := eq_of_aMapCode h hdε heι hde
        subst this
        exact aMap_aMap _ hd _ hdγ _ heκ

theorem equiv_equivalence : Equivalence ((· ≡ ·) : Code α → Code α → Prop) :=
  ⟨refl, fun {_ _} h => symm h, fun {_ _ _} h₁ h₂ => trans h₁ h₂⟩

theorem nonempty_iff : ∀ {c d : Code α}, c ≡ d → (c.2.Nonempty ↔ d.2.Nonempty)
  | _, _, refl _ => Iff.rfl
  | _, _, aMap_left _ _ _ _ => aMapCode_nonempty
  | _, _, aMap_right _ _ _ _ => aMapCode_nonempty.symm
  | _, _, aMap_aMap _ _ _ _ _ _ => aMapCode_nonempty.trans aMapCode_nonempty.symm

theorem ext : ∀ {c d : Code α}, c ≡ d → c.1 = d.1 → c = d
  | _, _, refl _, _ => rfl
  | _, _, aMap_left c _ β h, H => (h H.symm).elim
  | _, _, aMap_right c _ β h, H => (h H).elim
  | _, _, aMap_aMap c _ β _ γ hcγ, H => by
    simp only [fst_aMapCode, Subtype.mk.injEq, coe_inj, Subtype.coe_inj] at H
    subst H
    rfl

@[simp]
theorem bot_left_iff {s} :
    mk ⊥ s ≡ c ↔ mk ⊥ s = c ∨ ∃ β : Iio α, c = mk β (aMap IioBot.bot_ne_coe s) := by
  simp [Equiv_iff, aMapCode_ne_bot.symm]
  rw [eq_comm]

@[simp]
theorem bot_right_iff {s} :
    c ≡ mk ⊥ s ↔ c = mk ⊥ s ∨ ∃ β : Iio α, c = mk β (aMap IioBot.bot_ne_coe s) := by
  simp [Equiv_iff, aMapCode_ne_bot.symm]
  rw [eq_comm]

@[simp]
theorem bot_bot_iff {s t} : (mk ⊥ s : Code α) ≡ mk ⊥ t ↔ s = t := by
  constructor
  · rw [bot_left_iff]
    rintro (h | ⟨β, h⟩)
    · simp only [mk_inj] at h
      exact h
    · rw [mk, Sigma.ext_iff] at h
      simp at h
  · rintro rfl
    rfl

theorem singleton (hβγ : β ≠ γ) (g : Tangle β) :
    mk β {g} ≡ mk γ (typedNearLitter '' localCardinal (fMap (coe_ne hβγ) g)) := by
  convert Equiv.aMap_right (mk β {g}) (isEven_singleton _) _ hβγ
  rw [aMapCode, extension, dif_neg, snd_mk, aMap_singleton]
  exact hβγ

theorem singleton_iff {g} :
    c ≡ mk β {g} ↔
    c = mk β {g} ∨ ∃ γ : Iio α,
      (c.1 : TypeIndex) = (γ : Λ) ∧ β ≠ γ ∧ c = aMapCode γ (mk β {g}) := by
  classical
  refine ⟨fun h => ?_, ?_⟩
  · rw [Equiv_iff] at h
    simp only [mem_Iio, isEven_singleton, fst_mk, Ne.def, SetCoe.exists, Iio.coe_mk,
      true_and_iff] at h
    obtain rfl | ⟨γ, hβγ, hcβ, rfl⟩ | ⟨-, γ, hγ, γne, h⟩ | ⟨d, -, γ, hγ, -, δ, hδ, δne, -, h⟩ :=
      h
    · exact Or.inl rfl
    · simp only [Subtype.coe_mk, SetCoe.exists, exists_and_left]
      exact Or.inr ⟨_, rfl, hβγ, hcβ, rfl⟩
    · cases congr_arg Sigma.fst h
      cases aMapCode_ne_singleton γne h.symm
    · cases congr_arg Sigma.fst h
      cases aMapCode_ne_singleton δne h.symm
  · rintro (rfl | ⟨γ, hc, hβγ, rfl⟩)
    · rfl
    · convert (singleton hβγ g).symm
      simp only [snd_mk, aMapCode, extension_ne _ _ hβγ, aMap_singleton]

end Equiv

theorem extension_eq_of_singleton_equiv_singleton {γ : IioBot α}
    {a : Tangle β} {b : Tangle γ}
    (h : (⟨β, {a}⟩ : Code α) ≡ ⟨γ, {b}⟩) : β = γ :=
  by
  obtain h | ⟨ε, hc, hβε, hA⟩ := Equiv.singleton_iff.1 h
  · exact (Sigma.ext_iff.1 h).1
  · exfalso
    refine aMapCode_ne_singleton ?_ hA.symm
    cases congr_arg Sigma.fst hA
    exact hβε

theorem IsEven.unique : ∀ {c d : Code α}, c.IsEven → d.IsEven → c ≡ d → c = d
  | c, _, _, _, Equiv.refl _ => rfl
  | _, _, _, _, Equiv.aMap_left d hd β hdβ => by cases (hd.aMapCode hdβ).not_isEven ‹_›
  | _, _, _, _, Equiv.aMap_right d hd β hcβ => by cases (hd.aMapCode hcβ).not_isEven ‹_›
  | _, _, _, _, Equiv.aMap_aMap e he β hcβ γ _ => by cases (he.aMapCode hcβ).not_isEven ‹_›

theorem exists_even_equiv : ∀ c : Code α, ∃ d : Code α, d ≡ c ∧ d.IsEven := by
  rintro ⟨β, s⟩
  obtain rfl | _ := s.eq_empty_or_nonempty
  · exact ⟨_, Equiv.empty_empty _ _, isEven_bot _⟩
  obtain heven | hodd := isEven_or_isOdd ⟨β, s⟩
  · exact ⟨_, Equiv.rfl, heven⟩
  simp_rw [IsOdd_iff, AMapRel_iff] at hodd
  obtain ⟨d, ⟨γ, hdγ, hc⟩, hd⟩ := id hodd
  exact ⟨d, (Equiv.aMap_right _ hd _ hdγ).trans (Equiv.of_eq hc.symm), hd⟩

protected theorem IsEven.exists_equiv_extension_eq (heven : c.IsEven) :
    ∃ d : Code α, d ≡ c ∧ d.1 = γ := by
  by_cases c.1 = γ
  · exact ⟨c, Equiv.rfl, h⟩
  · exact ⟨aMapCode γ c, Equiv.aMap_left _ heven _ h, rfl⟩

theorem exists_equiv_extension_eq : ∀ c : Code α, ∃ d : Code α, d ≡ c ∧ d.1 = γ := by
  intro c
  obtain ⟨d, hd₁, hd₂⟩ := exists_even_equiv c
  obtain ⟨e, he₁, he₂⟩ : ∃ e : Code α, e ≡ d ∧ e.1 = γ := hd₂.exists_equiv_extension_eq
  exact ⟨e, he₁.trans hd₁, he₂⟩

theorem Equiv.unique : ∀ {c d : Code α}, c ≡ d → c.1 = d.1 → c = d
  | c, _, Equiv.refl _, _ => rfl
  | _, _, Equiv.aMap_left d _ β hdβ, h => by cases hdβ h.symm
  | _, _, Equiv.aMap_right d _ β hcβ, h => by cases hcβ h
  | _, _, Equiv.aMap_aMap e _ β _ γ _, h => by
      have : β = γ := Iio.coe_injective h
      subst this
      rfl

theorem equiv_bot_subsingleton (d e : Code α)
    (hdc : d ≡ c) (hec : e ≡ c) (hd : d.1 = ⊥) (he : e.1 = ⊥) : d = e :=
  (hdc.trans hec.symm).unique (hd.trans he.symm)

end Code

end ConNF
