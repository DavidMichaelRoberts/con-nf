import ConNF.Mathlib.Logic
import ConNF.Phase1.Code
import ConNF.Phase1.FMap

/-!
# Alternative extensions

The alternative extension map, aka A-map, from `γ` to `β` sends a code of extension `γ` to its
lternative extension `β`. This will used to identify codes and construct the TTT objects.

An important property for intuition is that A-maps have disjoint ranges (except on empty codes) and
are each injective, so if we connect each code to its images under A-maps, we get a tree (except for
empty codes that form a complete graph).

## Main declarations

* `con_nf.aMap`: Alternative extension map as a map from sets of `γ`-tangles to of `β`-tangles.
  Note that `γ` can be any type index while `β` has to be a proper type index.
* `con_nf.aMapCode`: Alternative extension map as a map from codes to codes of extension `β`.
* `con_nf.aMap_rel`: The relation on codes generated by `aMapCode`. It relates `c` to `d` iff `d`
  is the image of `c` under some A-map. This relation is well-founded on **nonempty** codes. See
  `con_nf.aMap_rel'_well_founded`.

## Notation

* `c ↝ d`: `d` is the image of `c` under some A-map.
-/


noncomputable section

open Function Set WithBot

open scoped Cardinal

universe u

namespace ConNF

variable [Params.{u}] [PositionData]

open Code

section AMap

variable {α : Λ} {γ : IioBot α} [CoreTangleData γ] [PositionedTangleData γ] {β : Iio α}
  [CoreTangleData (iioCoe β)] [PositionedTangleData (iioCoe β)] [AlmostTangleData β] (hγβ : γ ≠ β)

theorem coe_ne : γ ≠ β → (γ : TypeIndex) ≠ (β : Λ) :=
  Subtype.coe_injective.ne

/-- The *alternative extension* map. For a set of tangles `G`, consider the code
`(α, γ, G)`. We then construct the non-empty set `D` such that `(α, β, D)` is an alternative
extension of the same object in TTT. -/
def aMap (s : Set (Tangle γ)) : Set (Tangle <| iioCoe β) :=
  typedNearLitter '' ⋃ t ∈ s, localCardinal (fMap (coe_ne hγβ) t)

variable {hγβ}

@[simp]
theorem mem_aMap {t : Tangle <| iioCoe β} {s : Set (Tangle γ)} :
    t ∈ aMap hγβ s ↔
      ∃ t' ∈ s, ∃ (N : NearLitter), N.1 = fMap (coe_ne hγβ) t' ∧ t = typedNearLitter N := by
  simp only [aMap, and_comm, mem_image, mem_iUnion, exists_prop]
  constructor
  · rintro ⟨N, ⟨t, ht₁, ht₂⟩, rfl⟩
    exact ⟨t, ht₂, N, ht₁, rfl⟩
  · rintro ⟨t, ht₂, N, ht₁, rfl⟩
    exact ⟨N, ⟨t, ht₁, ht₂⟩, rfl⟩

@[simp]
theorem aMap_empty : aMap hγβ (∅ : Set (Tangle γ)) = ∅ := by
  simp only [aMap, mem_empty_iff_false, iUnion_of_empty, iUnion_empty, image_empty]

@[simp]
theorem aMap_singleton (t) :
    aMap hγβ ({t} : Set (Tangle γ)) = typedNearLitter '' localCardinal (fMap (coe_ne hγβ) t) := by
  simp only [aMap, mem_singleton_iff, iUnion_iUnion_eq_left]

variable {s : Set (Tangle γ)} {t : Tangle γ}

theorem _root_.Set.Nonempty.aMap (h : s.Nonempty) : (aMap hγβ s).Nonempty := by
  refine (nonempty_iUnion.2 ?_).image _
  refine ⟨h.choose, ⟨(fMap (coe_ne hγβ) h.choose).toNearLitter, ?_⟩⟩
  simp only [mem_iUnion, mem_localCardinal, Litter.toNearLitter_fst, exists_prop, and_true]
  exact h.choose_spec

@[simp]
theorem aMap_eq_empty (hγβ : γ ≠ β) : aMap hγβ s = ∅ ↔ s = ∅ :=
  by
  refine' ⟨fun h => not_nonempty_iff_eq_empty.1 fun hs => hs.aMap.ne_empty h, _⟩
  rintro rfl
  exact aMap_empty

@[simp]
theorem aMap_nonempty (hγβ : γ ≠ β) : (aMap hγβ s).Nonempty ↔ s.Nonempty := by
  simp_rw [nonempty_iff_ne_empty, Ne.def, aMap_eq_empty]

theorem subset_aMap (ht : t ∈ s) :
    typedNearLitter '' localCardinal (fMap (coe_ne hγβ) t) ⊆ aMap hγβ s :=
  image_subset _ <| subset_iUnion₂ (s := fun t' _ => localCardinal (fMap (coe_ne hγβ) t')) t ht

theorem μ_le_mk_aMap : s.Nonempty → #μ ≤ #(aMap hγβ s) := by
  rintro ⟨t, ht⟩
  refine' (Cardinal.mk_le_mk_of_subset <| subset_aMap ht).trans_eq' _
  rw [Cardinal.mk_image_eq, mk_localCardinal]
  exact typedNearLitter.inj'

theorem aMap_injective : Injective (aMap hγβ) :=
  typedNearLitter.injective.image_injective.comp <|
    Pairwise.biUnion_injective (fun _ _ h => localCardinal_disjoint <| (fMap_injective _).ne h)
      fun _ => localCardinal_nonempty _

variable {δ : IioBot α} [CoreTangleData δ] [PositionedTangleData δ]
  {hδβ : (δ : TypeIndex) ≠ (β : Λ)}

theorem aMap_disjoint_range {hδβ} (c : Set (Tangle γ)) (d : Set (Tangle δ)) (hc : c.Nonempty)
    (h : aMap hγβ c = aMap hδβ d) : γ = δ := by
  obtain ⟨b, hb⟩ := hc
  have := (subset_iUnion₂ b hb).trans (typedNearLitter.injective.image_injective h).subset
  obtain ⟨i, -, hi⟩ := mem_iUnion₂.1 (this (fMap _ b).toNearLitter_mem_localCardinal)
  refine Subtype.coe_injective ?_
  exact (fMap_β (coe_ne hγβ) b).trans ((congr_arg Litter.β hi).trans (fMap_β (coe_ne hδβ) i))

/-!
We don't need to prove that the ranges of the `A_δ` are disjoint for different `β`, since this holds
at the type level.

We now show that there are only finitely many iterated images under any inverse A-map, in the case
of nonempty sets.
-/

theorem wellFounded_position : WellFounded fun a b : Tangle γ => position a < position b :=
  InvImage.wf _ IsWellFounded.wf

/-- The minimum tangle of a nonempty set of tangles. -/
noncomputable def minTangle (c : Set (Tangle γ)) (hc : c.Nonempty) : Tangle γ :=
  wellFounded_position.min c hc

theorem minTangle_mem (c : Set (Tangle γ)) (hc : c.Nonempty) : minTangle c hc ∈ c :=
  WellFounded.min_mem _ c hc

theorem minTangle_le (c : Set (Tangle γ)) (hc : c.Nonempty) {x} (hx : x ∈ c) :
    position (minTangle c hc) ≤ position x :=
  not_lt.1 <| wellFounded_position.not_lt_min c hc hx

theorem aMap_order (c : Set (Tangle γ)) (hc : c.Nonempty) :
    position (minTangle c hc) < position (minTangle (aMap hγβ c) hc.aMap) := by
  obtain ⟨t, ht, s, hs, h⟩ := mem_aMap.1 (minTangle_mem (aMap hγβ c) hc.aMap)
  refine (minTangle_le c hc ht).trans_lt ?_
  rw [h]
  exact fMap_position (coe_ne hγβ) t _ hs

end AMap

section AMapCode

variable {α : Λ} [CoreTangleCumul α] [PositionedTangleCumul α]

/-- Tool that lets us use well-founded recursion on codes via `μ`. -/
noncomputable def codeMinMap (c : NonemptyCode α) : μ :=
  position <| minTangle _ c.prop

/-- The pullback `<` relation on codes is well-founded. -/
theorem code_wf : WellFounded (InvImage μr (codeMinMap : NonemptyCode α → μ)) :=
  InvImage.wf codeMinMap μwf.wf

section Extension

variable [AlmostTangleCumul α] {β : IioBot α}

/-- The A-map, phrased as a function on sets of `γ`-tangles, but if `γ = β`, this is the
identity function. This is the true alternative extension map. -/
def extension (s : Set (Tangle β)) (γ : Iio α) : Set (Tangle γ) :=
  if hβγ : β = γ then cast (by rw [hβγ]) s else aMap hβγ s

@[simp]
theorem extension_self {γ : Iio α} (s : Set (Tangle (iioCoe γ))) : extension s γ = s :=
  dif_pos rfl

variable (s : Set (Tangle β)) (γ : Iio α)

@[simp]
theorem extension_eq (hβγ : β = γ) : extension s γ = cast (by rw [hβγ]) s :=
  dif_pos hβγ

@[simp]
theorem extension_ne (hβγ : β ≠ γ) : extension s γ = aMap hβγ s :=
  dif_neg hβγ

end Extension

variable [AlmostTangleCumul α] (γ : IioBot α) (β : Iio α) (c d : Code α)

/-- The A-map, phrased as a function on `α`-codes, but if the code's level matches `β`, this is the
identity function. This is written in a weird way in order to make `(aMapCode β c).1` defeq
to `β`. -/
def aMapCode (c : Code α) : Code α :=
  mk β (extension c.2 β)

theorem aMapCode_eq (hcβ : c.1 = β) : aMapCode β c = c :=
  by
  rw [aMapCode, extension_eq _ _ hcβ]
  ext : 1
  · exact hcβ.symm
  · simp only [snd_mk, cast_heq]

theorem aMapCode_ne (hcβ : c.1 ≠ β) : aMapCode β c = mk β (aMap hcβ c.2) := by
  rw [aMapCode, extension_ne _ _ hcβ]

@[simp]
theorem fst_aMapCode : (aMapCode β c).1 = β :=
  rfl

@[simp]
theorem snd_aMapCode (hcβ : c.1 ≠ β) : (aMapCode β c).2 = aMap hcβ c.2 := by
  have := aMapCode_ne β c hcβ
  rw [Sigma.ext_iff] at this
  exact this.2.eq

@[simp]
theorem aMapCode_mk_eq (s) : aMapCode β (mk β s) = mk β s := by rw [aMapCode_eq]; rfl

@[simp]
theorem aMapCode_mk_ne (hγβ : γ ≠ β) (s) : aMapCode β (mk γ s) = mk β (aMap hγβ s) := by
  rw [aMapCode_ne β (mk γ s) hγβ]; rfl

variable {β c d}

@[simp]
theorem aMapCode_isEmpty : (aMapCode β c).IsEmpty ↔ c.IsEmpty :=
  by
  obtain ⟨γ, s⟩ := c
  by_cases γ = β
  · rw [aMapCode_eq]
    exact h
  · rw [aMapCode_ne]
    exact aMap_eq_empty h
    exact h

@[simp]
theorem aMapCode_nonempty : (aMapCode β c).2.Nonempty ↔ c.2.Nonempty := by
  simp_rw [nonempty_iff_ne_empty]; exact aMapCode_isEmpty.not

alias ⟨_, Code.IsEmpty.aMapCode⟩ := aMapCode_isEmpty

theorem aMapCode_injOn : {c : Code α | c.1 ≠ β ∧ c.2.Nonempty}.InjOn (aMapCode β) := by
  rintro ⟨γ, s⟩ ⟨hγβ, hs⟩ ⟨δ, t⟩ ⟨hδβ, ht⟩ h
  rw [aMapCode_ne _ _ hγβ, aMapCode_ne _ _ hδβ] at h
  have := (congr_arg_heq Sigma.snd h).eq
  simp only [fst_mk, snd_mk] at this
  obtain rfl := aMap_disjoint_range _ _ hs this
  rw [aMap_injective this]

theorem μ_le_mk_aMapCode (c : Code α) (hcβ : c.1 ≠ β) : c.2.Nonempty → #μ ≤ #(aMapCode β c).2 := by
  rw [aMapCode_ne β c hcβ]
  exact μ_le_mk_aMap (hγβ := hcβ)

variable (β)

theorem aMapCode_order (c : NonemptyCode α) (hcβ : c.1.1 ≠ β) :
    codeMinMap c < codeMinMap ⟨aMapCode β c, aMapCode_nonempty.mpr c.2⟩ := by
  unfold codeMinMap
  have := aMapCode_ne β c hcβ
  convert aMap_order c.1.2 c.2 using 1
  congr
  exact snd_aMapCode β c hcβ

/-- This relation on `α`-codes allows us to state that there are only finitely many iterated images
under the inverse A-map. Note that we require the A-map to actually change the data, by requiring
that `c.1 ≠ β`. -/
@[mk_iff]
inductive AMapRel (c : Code α) : Code α → Prop
  | intro (β : Iio α) : c.1 ≠ β → AMapRel c (aMapCode β c)

infixl:62 " ↝ " => AMapRel

theorem aMapRel_subsingleton (hc : c.2.Nonempty) : {d : Code α | d ↝ c}.Subsingleton := by
  intro d hd e he
  simp only [AMapRel_iff] at hd he
  obtain ⟨⟨β, hβ⟩, hdβ, rfl⟩ := hd
  obtain ⟨⟨γ, hγ⟩, heγ, h⟩ := he
  have := congr_arg Subtype.val (Sigma.ext_iff.1 h).1
  dsimp only [fst_aMapCode, Iio.coe_mk] at this
  rw [coe_eq_coe] at this
  subst this
  refine' aMapCode_injOn ⟨hdβ, aMapCode_nonempty.1 hc⟩ _ h
  rw [h] at hc
  exact ⟨heγ, aMapCode_nonempty.1 hc⟩

theorem aMapRel_aMapCode (hd : d.2.Nonempty) (hdβ : d.1 ≠ β) : c ↝ aMapCode β d ↔ c = d := by
  refine'
    ⟨fun h => aMapRel_subsingleton (by rwa [aMapCode_nonempty]) h <| AMapRel.intro _ hdβ, _⟩
  rintro rfl
  exact ⟨_, hdβ⟩

theorem AMapRel.nonempty_iff : c ↝ d → (c.2.Nonempty ↔ d.2.Nonempty) := by
  rintro ⟨β, hcβ⟩
  exact aMapCode_nonempty.symm

theorem aMapRelEmptyEmpty (hγβ : γ ≠ β) : mk γ ∅ ↝ mk β ∅ :=
  (AMapRel_iff _ _).2
    ⟨β, hγβ, by
      ext : 1
      · rfl
      · refine heq_of_eq ?_
        simp only [snd_mk, snd_aMapCode _ (mk γ ∅) hγβ, aMap_empty]⟩

theorem eq_of_aMapCode {β γ : Iio α} (hc : c.2.Nonempty) (hcβ : c.1 ≠ β) (hdγ : d.1 ≠ γ)
    (h : aMapCode β c = aMapCode γ d) : c = d := by
  refine aMapRel_subsingleton (by rwa [aMapCode_nonempty]) (AMapRel.intro _ hcβ) ?_
  rw [h]
  exact AMapRel.intro _ hdγ

/-- This relation on `α`-codes allows us to state that there are only finitely many iterated images
under the inverse A-map. -/
@[mk_iff]
inductive AMapRel' (c : NonemptyCode α) : NonemptyCode α → Prop
  | intro (β : Iio α) : (c : Code α).1 ≠ β → AMapRel' c ⟨aMapCode β c, aMapCode_nonempty.mpr c.2⟩

@[simp]
theorem aMapRel_coe_coe {c d : NonemptyCode α} : (c : Code α) ↝ d ↔ AMapRel' c d := by
  rw [AMapRel_iff, AMapRel'_iff, Iff.comm]
  exact exists_congr fun β => and_congr_right' Subtype.ext_iff

theorem aMap_subrelation : Subrelation AMapRel' (InvImage μr (codeMinMap : NonemptyCode α → μ))
  | c, _, AMapRel'.intro β hc => aMapCode_order β c hc

/-- There are only finitely many iterated images under any inverse A-map. -/
theorem aMapRel'_wellFounded : WellFounded (AMapRel' : _ → NonemptyCode α → Prop) :=
  aMap_subrelation.wf code_wf

instance : WellFoundedRelation (NonemptyCode α) :=
  ⟨_, aMapRel'_wellFounded⟩

/-- There is at most one inverse under an A-map. This corresponds to the fact that there is only one
code which is related (on the left) to any given code under the A-map relation. -/
theorem aMapRel'_subsingleton (c : NonemptyCode α) :
    {d : NonemptyCode α | AMapRel' d c}.Subsingleton :=
  by
  intro d hd e he
  simp only [Ne.def, AMapRel'_iff, mem_setOf_eq] at hd he
  obtain ⟨⟨β, hβ⟩, hdβ, rfl⟩ := hd
  obtain ⟨⟨γ, hγ⟩, heγ, h⟩ := he
  rw [Subtype.ext_iff] at h
  have := congr_arg Subtype.val (Sigma.ext_iff.1 h).1
  simp only [Subtype.coe_mk, fst_aMapCode, Iio.coe_mk, coe_eq_coe] at this
  subst this
  exact Subtype.coe_injective (aMapCode_injOn ⟨hdβ, d.2⟩ ⟨heγ, e.2⟩ h)

end AMapCode

end ConNF
