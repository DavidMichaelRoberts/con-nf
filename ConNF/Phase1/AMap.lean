import ConNF.Mathlib.Logic
import ConNF.Phase1.Code
import ConNF.Phase1.FMap

#align_import phase1.A_map

/-!
# Alternative extensions

The alternative extension map, aka A-map, from `γ` to `β` sends a code of extension `γ` to its
lternative extension `β`. This will used to identify codes and construct the TTT objects.

An important property for intuition is that A-maps have disjoint ranges (except on empty codes) and
are each injective, so if we connect each code to its images under A-maps, we get a tree (except for
empty codes that form a complete graph).

## Main declarations

* `con_nf.A_map`: Alternative extension map as a map from sets of `γ`-tangles to of `β`-tangles.
  Note that `γ` can be any type index while `β` has to be a proper type index.
* `con_nf.A_map_code`: Alternative extension map as a map from codes to codes of extension `β`.
* `con_nf.A_map_rel`: The relation on codes generated by `A_map_code`. It relates `c` to `d` iff `d`
  is the image of `c` under some A-map. This relation is well-founded on **nonempty** codes. See
  `con_nf.A_map_rel'_well_founded`.

## Notation

* `c ↝ d`: `d` is the image of `c` under some A-map.
-/


noncomputable section

open Function Set WithBot

open scoped Cardinal

universe u

namespace ConNf

variable [Params.{u}] [PositionData]

open Code

section AMap

variable {α : Λ} {γ : iioIndex α} [CoreTangleData γ] [PositionedTangleData γ] {β : Iio α}
  [CoreTangleData (iioCoe β)] [PositionedTangleData (iioCoe β)] [AlmostTangleData β] (hγβ : γ ≠ β)

theorem coe_ne : γ ≠ β → (γ : TypeIndex) ≠ (β : Λ) :=
  Subtype.coe_injective.Ne

/-- The *alternative extension* map. For a set of tangles `G`, consider the code
`(α, γ, G)`. We then construct the non-empty set `D` such that `(α, β, D)` is an alternative
extension of the same object in TTT. -/
def aMap (s : Set (Tangle γ)) : Set (Tangle <| iioCoe β) :=
  typedNearLitter '' ⋃ t ∈ s, localCardinal (fMap (coe_ne hγβ) t)

variable {β} {hγβ}

@[simp]
theorem mem_aMap {t : Tangle <| iioCoe β} {s : Set (Tangle γ)} :
    t ∈ aMap hγβ s ↔
      ∃ t' ∈ s,
        ∃ (N : _) (hN : IsNearLitter (fMap (coe_ne hγβ) t') N), typedNearLitter ⟨_, N, hN⟩ = t :=
  by
  simp only [A_map, and_comm', mem_image, mem_Union, exists_prop]
  constructor
  · rintro ⟨⟨i, N, hN⟩, rfl, t, ht₁, ⟨rfl, ht₂⟩⟩
    exact ⟨t, ht₁, N, _, rfl⟩
  · rintro ⟨t, ht, N, hN, rfl⟩; cases hN
    exact ⟨⟨f_map (coe_ne hγβ) t, N, _⟩, rfl, t, ht, rfl⟩

@[simp]
theorem aMap_empty : aMap hγβ (∅ : Set (Tangle γ)) = ∅ := by
  simp only [A_map, Union_false, Union_empty, image_empty]

@[simp]
theorem aMap_singleton (t) :
    aMap hγβ ({t} : Set (Tangle γ)) = typedNearLitter '' localCardinal (fMap (coe_ne hγβ) t) := by
  simp only [A_map, mem_singleton_iff, Union_Union_eq_left]

variable {s : Set (Tangle γ)} {t : Tangle γ}

theorem Set.Nonempty.aMap (h : s.Nonempty) : (aMap hγβ s).Nonempty :=
  by
  refine' (nonempty_bUnion.2 _).image _
  exact
    h.imp fun t ht => ⟨ht, ⟨f_map (coe_ne hγβ) _, litter_set _, is_near_litter_litter_set _⟩, rfl⟩

@[simp]
theorem aMap_eq_empty (hγβ : γ ≠ β) : aMap hγβ s = ∅ ↔ s = ∅ :=
  by
  refine' ⟨fun h => not_nonempty_iff_eq_empty.1 fun hs => hs.A_map.ne_empty h, _⟩
  rintro rfl
  exact A_map_empty

@[simp]
theorem aMap_nonempty (hγβ : γ ≠ β) : (aMap hγβ s).Nonempty ↔ s.Nonempty := by
  simp_rw [nonempty_iff_ne_empty, Ne.def, A_map_eq_empty]

theorem subset_aMap (ht : t ∈ s) :
    typedNearLitter '' localCardinal (fMap (coe_ne hγβ) t) ⊆ aMap hγβ s :=
  image_subset _ <| subset_iUnion₂ t ht

theorem μ_le_mk_aMap : s.Nonempty → (#μ) ≤ (#aMap hγβ s) :=
  by
  rintro ⟨t, ht⟩
  refine' (Cardinal.mk_le_mk_of_subset <| subset_A_map ht).trans_eq' _
  rw [Cardinal.mk_image_eq, mk_local_cardinal]
  exact typed_near_litter.inj'

theorem aMap_injective : Injective (aMap hγβ) :=
  typedNearLitter.Injective.image_injective.comp <|
    Pairwise.biUnion_injective (fun x y h => localCardinal_disjoint <| (fMap_injective _).Ne h)
      fun _ => localCardinal_nonempty _

variable {δ : iioIndex α} [CoreTangleData δ] [PositionedTangleData δ]
  {hδβ : (δ : TypeIndex) ≠ (β : Λ)}

theorem aMap_disjoint_range {hδβ} (c : Set (Tangle γ)) (d : Set (Tangle δ)) (hc : c.Nonempty)
    (h : aMap hγβ c = aMap hδβ d) : γ = δ :=
  by
  obtain ⟨b, hb⟩ := hc
  have := (subset_Union₂ b hb).trans (typed_near_litter.injective.image_injective h).Subset
  obtain ⟨i, -, hi⟩ := mem_Union₂.1 (this (f_map _ b).toNearLitter_mem_localCardinal)
  refine' Subtype.coe_injective _
  exact (f_map_β (coe_ne hγβ) b).trans ((congr_arg litter.β hi).trans (f_map_β (coe_ne hδβ) i))

/-!
We don't need to prove that the ranges of the `A_δ` are disjoint for different `β`, since this holds
at the type level.

We now show that there are only finitely many iterated images under any inverse A-map, in the case
of nonempty sets.
-/


variable {γ}

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
    position (minTangle c hc) < position (minTangle (aMap hγβ c) hc.aMap) :=
  by
  obtain ⟨t, ht, s, hs, h⟩ := mem_A_map.1 (min_tangle_mem (A_map hγβ c) hc.A_map)
  rw [← h]
  refine' (min_tangle_le c hc ht).trans_lt (f_map_position (coe_ne hγβ) t _ hs)

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

variable [AlmostTangleCumul α] {β : iioIndex α}

/-- The A-map, phrased as a function on sets of `γ`-tangles, but if `γ = β`, this is the
identity function. This is the true alternative extension map. -/
def extension (s : Set (Tangle β)) (γ : Iio α) : Set (Tangle γ) :=
  if hβγ : β = γ then cast (by rw [hβγ] <;> rfl) s else aMap hβγ s

@[simp]
theorem extension_self {γ : Iio α} (s : Set (Tangle (iioCoe γ))) : extension s γ = s :=
  dif_pos rfl

variable (s : Set (Tangle β)) (γ : Iio α)

@[simp]
theorem extension_eq (hβγ : β = γ) : extension s γ = cast (by rw [hβγ] <;> rfl) s :=
  dif_pos hβγ

@[simp]
theorem extension_ne (hβγ : β ≠ γ) : extension s γ = aMap hβγ s :=
  dif_neg hβγ

end Extension

variable [AlmostTangleCumul α] (γ : iioIndex α) (β : Iio α) (c d : Code α)

/-- The A-map, phrased as a function on `α`-codes, but if the code's level matches `β`, this is the
identity function. This is written in a weird way in order to make `(A_map_code β c).1` defeq
to `β`. -/
def aMapCode (c : Code α) : Code α :=
  mk β (extension c.2 β)

theorem aMapCode_eq (hcβ : c.1 = β) : aMapCode β c = c :=
  by
  rw [A_map_code, extension_eq _ _ hcβ]
  ext : 1
  · exact hcβ.symm
  · simp only [snd_mk, cast_hEq]

theorem aMapCode_ne (hcβ : c.1 ≠ β) : aMapCode β c = mk β (aMap hcβ c.2) := by
  rw [A_map_code, extension_ne _ _ hcβ]

@[simp]
theorem fst_aMapCode : (aMapCode β c).1 = β :=
  rfl

@[simp]
theorem snd_aMapCode (hcβ : c.1 ≠ β) : (aMapCode β c).2 = aMap hcβ c.2 :=
  by
  have := A_map_code_ne β c hcβ
  rw [Sigma.ext_iff] at this
  exact this.2.Eq

@[simp]
theorem aMapCode_mk_eq (s) : aMapCode β (mk β s) = mk β s := by rw [A_map_code_eq]; rfl

@[simp]
theorem aMapCode_mk_ne (hγβ : γ ≠ β) (s) : aMapCode β (mk γ s) = mk β (aMap hγβ s) := by
  rw [A_map_code_ne β (mk γ s) hγβ]; rfl

variable {β c d}

@[simp]
theorem aMapCode_isEmpty : (aMapCode β c).isEmpty ↔ c.isEmpty :=
  by
  obtain ⟨γ, s⟩ := c
  by_cases γ = β
  · rw [A_map_code_eq]
    exact h
  · rw [A_map_code_ne]
    exact A_map_eq_empty h

@[simp]
theorem aMapCode_nonempty : (aMapCode β c).2.Nonempty ↔ c.2.Nonempty := by
  simp_rw [nonempty_iff_ne_empty]; exact A_map_code_is_empty.not

alias A_map_code_is_empty ↔ _ code.is_empty.A_map_code

attribute [protected] code.is_empty.A_map_code

theorem aMapCode_injOn : {c : Code α | c.1 ≠ β ∧ c.2.Nonempty}.InjOn (aMapCode β) :=
  by
  rintro ⟨⟨γ, hγ⟩, s⟩ ⟨hγβ, hs⟩ ⟨⟨δ, hδ⟩, t⟩ ⟨hδβ, ht⟩ h
  rw [A_map_code_ne _ _ hγβ, A_map_code_ne _ _ hδβ] at h
  have := (congr_arg_heq Sigma.snd h).Eq
  dsimp only at this
  obtain rfl : γ = δ := congr_arg Subtype.val (A_map_disjoint_range _ _ hs this)
  rw [A_map_injective this]

theorem μ_le_mk_aMapCode (c : Code α) (hcβ : c.1 ≠ β) : c.2.Nonempty → (#μ) ≤ (#(aMapCode β c).2) :=
  by rw [A_map_code_ne β c hcβ]; exact μ_le_mk_A_map

variable (β)

theorem aMapCode_order (c : NonemptyCode α) (hcβ : c.1.1 ≠ β) :
    codeMinMap c < codeMinMap ⟨aMapCode β c, aMapCode_nonempty.mpr c.2⟩ :=
  by
  unfold code_min_map
  have := A_map_code_ne β c hcβ
  convert A_map_order c.1.2 c.2 using 1
  congr
  exact snd_A_map_code β c hcβ

/-- This relation on `α`-codes allows us to state that there are only finitely many iterated images
under the inverse A-map. Note that we require the A-map to actually change the data, by requiring
that `c.1 ≠ β`. -/
@[mk_iff]
inductive AMapRel (c : Code α) : Code α → Prop
  | intro (β : Iio α) : c.1 ≠ β → A_map_rel (aMapCode β c)

infixl:62 " ↝ " => AMapRel

theorem aMapRel_subsingleton (hc : c.2.Nonempty) : {d : Code α | d ↝ c}.Subsingleton :=
  by
  intro d hd e he
  simp only [A_map_rel_iff] at hd he
  obtain ⟨⟨β, hβ⟩, hdβ, rfl⟩ := hd
  obtain ⟨⟨γ, hγ⟩, heγ, h⟩ := he
  have := congr_arg Subtype.val (Sigma.ext_iff.1 h).1
  dsimp only [fst_A_map_code, Iio.coe_mk] at this
  rw [coe_eq_coe] at this
  subst this
  refine' A_map_code_inj_on ⟨hdβ, A_map_code_nonempty.1 hc⟩ _ h
  rw [h] at hc
  exact ⟨heγ, A_map_code_nonempty.1 hc⟩

theorem aMapRel_aMapCode (hd : d.2.Nonempty) (hdβ : d.1 ≠ β) : c ↝ aMapCode β d ↔ c = d :=
  by
  refine'
    ⟨fun h => A_map_rel_subsingleton (by rwa [A_map_code_nonempty]) h <| A_map_rel.intro _ hdβ, _⟩
  rintro rfl
  exact ⟨_, hdβ⟩

theorem AMapRel.nonempty_iff : c ↝ d → (c.2.Nonempty ↔ d.2.Nonempty) := by rintro ⟨β, hcβ⟩;
  exact A_map_code_nonempty.symm

theorem aMapRelEmptyEmpty (hγβ : γ ≠ β) : mk γ ∅ ↝ mk β ∅ :=
  (aMapRel_iff _ _).2
    ⟨β, hγβ, by
      ext : 1
      · rfl
      · refine' hEq_of_eq _
        simp only [snd_mk, snd_A_map_code _ (mk γ ∅) hγβ, A_map_empty]⟩

theorem eq_of_aMapCode {β γ : Iio α} (hc : c.2.Nonempty) (hcβ : c.1 ≠ β) (hdγ : d.1 ≠ γ)
    (h : aMapCode β c = aMapCode γ d) : c = d :=
  by
  refine' A_map_rel_subsingleton (by rwa [A_map_code_nonempty]) (A_map_rel.intro _ hcβ) _
  simp_rw [h]
  exact A_map_rel.intro _ hdγ

/-- This relation on `α`-codes allows us to state that there are only finitely many iterated images
under the inverse A-map. -/
@[mk_iff]
inductive AMapRel' (c : NonemptyCode α) : NonemptyCode α → Prop
  | intro (β : Iio α) : (c : Code α).1 ≠ β → A_map_rel' ⟨aMapCode β c, aMapCode_nonempty.mpr c.2⟩

@[simp]
theorem aMapRel_coe_coe {c d : NonemptyCode α} : (c : Code α) ↝ d ↔ AMapRel' c d :=
  by
  rw [A_map_rel_iff, A_map_rel'_iff, Iff.comm]
  exact exists_congr fun β => and_congr_right' Subtype.ext_iff

theorem A_map_subrelation : Subrelation AMapRel' (InvImage μr (codeMinMap : NonemptyCode α → μ))
  | c, _, A_map_rel'.intro β hc => aMapCode_order β c hc

/-- There are only finitely many iterated images under any inverse A-map. -/
theorem aMapRel'_wellFounded : WellFounded (AMapRel' : _ → NonemptyCode α → Prop) :=
  A_map_subrelation.wf code_wf

instance : WellFoundedRelation (NonemptyCode α) :=
  ⟨_, aMapRel'_wellFounded⟩

/-- There is at most one inverse under an A-map. This corresponds to the fact that there is only one
code which is related (on the left) to any given code under the A-map relation. -/
theorem aMapRel'_subsingleton (c : NonemptyCode α) :
    {d : NonemptyCode α | AMapRel' d c}.Subsingleton :=
  by
  intro d hd e he
  simp only [Subtype.val_eq_coe, Ne.def, A_map_rel'_iff, mem_set_of_eq] at hd he
  obtain ⟨⟨β, hβ⟩, hdβ, rfl⟩ := hd
  obtain ⟨⟨γ, hγ⟩, heγ, h⟩ := he
  rw [Subtype.ext_iff] at h
  have := congr_arg Subtype.val (Sigma.ext_iff.1 h).1
  simp only [Subtype.coe_mk, fst_A_map_code, Iio.coe_mk, coe_eq_coe] at this
  subst this
  exact Subtype.coe_injective (A_map_code_inj_on ⟨hdβ, d.2⟩ ⟨heγ, e.2⟩ h)

end AMapCode

end ConNf