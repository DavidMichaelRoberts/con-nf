import phase2.complete_orbit
import phase2.flexible_completion

open cardinal set sum
open_locale cardinal classical

universe u

namespace con_nf

namespace struct_approx
variables [params.{u}] {α : Λ} [position_data.{}] [phase_2_assumptions α] {β : Iic α} {δ : Iio α}

/-- A support, together with values of an allowable permutation on that support. See also
`hypothesis` for a different formulation of similar data. -/
@[ext] structure support_map (δ : Iio α) :=
(carrier : set (support_condition δ))
(small : small carrier)
(atom_image : Π a B, (inl a, B) ∈ carrier → atom)
(near_litter_image : Π N B, (inr N, B) ∈ carrier → near_litter)

instance : has_mem (support_condition δ) (support_map δ) := ⟨λ c M, c ∈ M.carrier⟩

@[mk_iff] structure support_map.le (M M' : support_map δ) : Prop :=
(carrier_subset : M.carrier ⊆ M'.carrier)
(map_atom : ∀ ⦃a B⦄ (h : (inl a, B) ∈ M.carrier),
  M.atom_image a B h = M'.atom_image a B (mem_of_mem_of_subset h carrier_subset))
(map_near_litter : ∀ ⦃N B⦄ (h : (inr N, B) ∈ M.carrier),
  M.near_litter_image N B h = M'.near_litter_image N B (mem_of_mem_of_subset h carrier_subset))

instance : partial_order (support_map δ) := {
  le := support_map.le,
  le_refl := λ M, ⟨subset.rfl, λ _ _ _, rfl, λ _ _ _, rfl⟩,
  le_trans := λ M₁ M₂ M₃ h₁ h₂,
    ⟨subset.trans h₁.carrier_subset h₂.carrier_subset,
    λ a B h, (h₁.map_atom h).trans (h₂.map_atom (h₁.carrier_subset h)),
    λ N B h, (h₁.map_near_litter h).trans (h₂.map_near_litter (h₁.carrier_subset h))⟩,
  le_antisymm := begin
    rintro ⟨S₁, hS₁, a₁, N₁⟩ ⟨S₂, hS₂, a₂, N₂⟩ h h',
    cases subset.antisymm h.carrier_subset h'.carrier_subset,
    simp only [eq_self_iff_true, heq_iff_eq, true_and],
    split;
    funext,
    exact h.map_atom _,
    exact h.map_near_litter _,
  end,
}

variable (M : support_map δ)

/-- A litter that is not allowed to be used as a sandbox because it appears somewhere that
we need to preserve. -/
@[mk_iff] inductive banned_litter (B : extended_index δ) : litter → Prop
| support_atom (a : atom) : (inl a, B) ∈ M → banned_litter a.1
| support_litter (L : litter) : (inr L.to_near_litter, B) ∈ M → banned_litter L
| map_atom (a : atom) (h) : banned_litter (M.atom_image a B h).1
| map_litter (N : near_litter) (h) : banned_litter (M.near_litter_image N B h).1
| map_diff (N : near_litter) (h) (a : atom) :
    a ∈ (M.near_litter_image N B h : set atom) \ litter_set (M.near_litter_image N B h).1 →
    banned_litter a.1

lemma banned_litter_small (B : extended_index δ) : small {L | banned_litter M B L} :=
begin
  simp only [banned_litter_iff, set_of_or, exists_and_distrib_right],
  refine small.union _ (small.union _ (small.union _ (small.union _ _))),
  { refine lt_of_le_of_lt _ M.small,
    refine ⟨⟨λ a, ⟨_, a.prop.some_spec.1⟩, λ a₁ a₂ h, _⟩⟩,
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff] at h,
    have := a₁.prop.some_spec.2,
    rw h.1 at this,
    exact subtype.coe_injective (this.trans a₂.prop.some_spec.2.symm), },
  { refine lt_of_le_of_lt _ M.small,
    refine ⟨⟨λ L, ⟨_, L.prop⟩, λ L₁ L₂ h, _⟩⟩,
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff] at h,
    exact subtype.coe_injective (litter.to_near_litter_injective h.1), },
  { refine lt_of_le_of_lt _ M.small,
    refine ⟨⟨λ L, ⟨_, L.prop.some_spec.some⟩, λ L₁ L₂ h, _⟩⟩,
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff] at h,
    have := L₁.prop.some_spec.some_spec,
    simp_rw h.1 at this,
    exact subtype.coe_injective (this.trans L₂.prop.some_spec.some_spec.symm), },
  { refine lt_of_le_of_lt _ M.small,
    refine ⟨⟨λ L, ⟨_, L.prop.some_spec.some⟩, λ L₁ L₂ h, _⟩⟩,
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff] at h,
    have := L₁.prop.some_spec.some_spec,
    simp_rw h.1 at this,
    exact subtype.coe_injective (this.trans L₂.prop.some_spec.some_spec.symm), },
  { have : small ⋃ (N : near_litter) (h : (inr N, B) ∈ M),
      (M.near_litter_image N B h : set atom) \ litter_set (M.near_litter_image N B h).1,
    { refine small.bUnion _ _,
      { refine lt_of_le_of_lt _ M.small,
        refine ⟨⟨λ N, ⟨_, N.prop⟩, λ N₁ N₂ h, _⟩⟩,
        simp only [subtype.mk_eq_mk, prod.mk.inj_iff] at h,
        ext : 1, exact h.1, },
      { intros N hN,
        refine small.mono _ (M.near_litter_image N B hN).2.prop,
        exact λ x hx, or.inr hx, }, },
    refine lt_of_le_of_lt _ this,
    refine ⟨⟨λ L, ⟨L.prop.some_spec.some_spec.some, _⟩, λ L₁ L₂ h, _⟩⟩,
    { simp only [mem_Union],
      exact ⟨_, _, L.prop.some_spec.some_spec.some_spec.1⟩, },
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff] at h,
    have := L₁.prop.some_spec.some_spec.some_spec.2,
    rw h at this,
    exact subtype.coe_injective
      (this.trans L₂.prop.some_spec.some_spec.some_spec.2.symm), },
end

/-- We need two non-banned litters for the construction. -/
lemma not_banned_litter_nontrivial (B : extended_index δ) : {L | ¬banned_litter M B L}.nontrivial :=
begin
  rw [← nontrivial_coe_sort, ← one_lt_iff_nontrivial],
  by_contra' h,
  have := mk_union_le {L | banned_litter M B L} {L | banned_litter M B L}ᶜ,
  rw [union_compl_self, mk_univ, mk_litter] at this,
  refine not_lt_of_le this (add_lt_of_lt μ_strong_limit.is_limit.aleph_0_le _ _),
  exact lt_trans (banned_litter_small M B) κ_lt_μ,
  exact lt_of_le_of_lt h (lt_of_lt_of_le one_lt_aleph_0 μ_strong_limit.is_limit.aleph_0_le),
end

/-- A litter used by the local permutation completion infrastructure to put orbits of atoms. -/
noncomputable def sandbox_litter (B : extended_index δ) : litter :=
(not_banned_litter_nontrivial M B).some.1

/-- A litter used to assign preimages to atoms in litters that we want nothing in the designated
support to map to. -/
noncomputable def preimage_litter (B : extended_index δ) : litter :=
(not_banned_litter_nontrivial M B).some.2

lemma sandbox_litter_not_banned (B : extended_index δ) :
  ¬banned_litter M B (sandbox_litter M B) :=
(not_banned_litter_nontrivial M B).some_fst_mem

lemma preimage_litter_not_banned (B : extended_index δ) :
  ¬banned_litter M B (preimage_litter M B) :=
(not_banned_litter_nontrivial M B).some_snd_mem

lemma sandbox_litter_ne_preimage_litter (B : extended_index δ) :
  sandbox_litter M B ≠ preimage_litter M B :=
(not_banned_litter_nontrivial M B).some_fst_ne_some_snd

/-- An atom and `δ`-extended index is called *without preimage* if it is not mapped to by
anything in the support, but it is in a litter near some near-litter that was mapped to.
Atoms without preimage need to have something map to it, so that the resulting map that we use in
the freedom of action theorem actually maps to the correct near-litter. -/
@[mk_iff] structure without_preimage (a : atom) (B : extended_index δ) : Prop :=
(mem_map : ∃ (L : litter) h, a ∈ litter_set (M.near_litter_image L.to_near_litter B h).1)
(not_mem_map : ∀ (L : litter) h, a ∉ M.near_litter_image L.to_near_litter B h)
(not_mem_domain : ∀ b h, a ≠ M.atom_image b B h)

lemma without_preimage_small (B : extended_index δ) :
  small {a | without_preimage M a B} :=
begin
  simp only [without_preimage_iff, set_of_and],
  rw ← inter_assoc,
  refine small.mono (inter_subset_left _ _) _,
  suffices : small ⋃ (L : litter) (h),
    litter_set (M.near_litter_image L.to_near_litter B h).1 \
      M.near_litter_image L.to_near_litter B h,
  { refine small.mono _ this,
    rintro a ⟨⟨L, hL, ha₁⟩, ha₂⟩,
    simp only [mem_Union],
    exact ⟨L, hL, ha₁, ha₂ _ _⟩, },
  refine small.bUnion _ _,
  { refine lt_of_le_of_lt _ M.small,
    refine ⟨⟨λ L, ⟨_, L.prop⟩, _⟩⟩,
    intros L₁ L₂ h,
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff, eq_self_iff_true, and_true,
      litter.to_near_litter_injective.eq_iff, subtype.coe_inj] at h,
    exact h, },
  { intros L hL,
    refine small.mono _
      (M.near_litter_image L.to_near_litter B hL).2.prop,
    exact λ x hx, or.inl hx, },
end

/-- The subset of the preimage litter that is put in correspondence with the set of
atoms without preimage. -/
def preimage_litter_subset (B : extended_index δ) : set atom :=
(le_mk_iff_exists_subset.mp
  (lt_of_lt_of_eq (without_preimage_small M B)
  (mk_litter_set (preimage_litter M B)).symm).le).some

section
variables {M}

lemma preimage_litter_subset_spec (B : extended_index δ) :
  preimage_litter_subset M B ⊆ litter_set (preimage_litter M B) ∧
    #(preimage_litter_subset M B) = #{a : atom | without_preimage M a B} :=
(le_mk_iff_exists_subset.mp
  (lt_of_lt_of_eq (without_preimage_small M B)
  (mk_litter_set (preimage_litter M B)).symm).le).some_spec

lemma preimage_litter_subset_subset (B : extended_index δ) :
  preimage_litter_subset M B ⊆ litter_set (preimage_litter M B) :=
(preimage_litter_subset_spec B).1

lemma preimage_litter_subset_small (B : extended_index δ) :
  small (preimage_litter_subset M B) :=
lt_of_eq_of_lt (preimage_litter_subset_spec B).2 (without_preimage_small M B)

end

@[irreducible] noncomputable def preimage_litter_equiv (B : extended_index δ) :
  preimage_litter_subset M B ≃ {a : atom | without_preimage M a B} :=
(cardinal.eq.mp (preimage_litter_subset_spec B).2).some

/-- The images of atoms in a litter `L` that were mapped outside the target litter, but
were not in the domain. -/
@[mk_iff] structure mapped_outside (L : litter) (B : extended_index δ)
  (h : (inr L.to_near_litter, B) ∈ M) (a : atom) : Prop :=
(mem_map : a ∈ (M.near_litter_image L.to_near_litter B h : set atom))
(not_mem_map :
  a ∉ litter_set (M.near_litter_image L.to_near_litter B h).1)
(not_mem_domain : ∀ b h, a ≠ M.atom_image b B h)

/-- There are only `< κ`-many atoms in a litter `L` that are mapped outside the image litter,
and that are not already in the domain. -/
lemma mapped_outside_small (L : litter) (B : extended_index δ) (h) :
  small {a | mapped_outside M L B h a} :=
begin
  simp only [mapped_outside_iff, set_of_and],
  rw ← inter_assoc,
  refine small.mono (inter_subset_left _ _) _,
  refine small.mono _ (M.near_litter_image L.to_near_litter B h).2.prop,
  exact λ x hx, or.inr hx,
end

section
variables {M}

lemma without_preimage.not_mapped_outside {a B} (h : without_preimage M a B) (L) (h') :
  ¬mapped_outside M L B h' a :=
λ ha, h.not_mem_map L h' (ha.mem_map)

lemma mapped_outside.not_without_preimage {L B h a} (ha : mapped_outside M L B h a) :
  ¬without_preimage M a B :=
λ ha', ha'.not_mem_map L h ha.mem_map

end

/-- The amount of atoms in a litter that are not in the domain already is `κ`. -/
lemma mk_mapped_outside_domain (L : litter) (B : extended_index δ) :
  #(litter_set L \ {a : atom | (inl a, B) ∈ M} : set atom) = #κ :=
begin
  refine le_antisymm _ _,
  { rw ← mk_litter_set,
    exact mk_subtype_mono (λ x hx, hx.1), },
  by_contra' h,
  have : small {a : atom | (inl a, B) ∈ M},
  { refine lt_of_le_of_lt _ M.small,
    refine ⟨⟨λ a, ⟨_, a.prop⟩, λ a b h, _⟩⟩,
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff, subtype.coe_inj, eq_self_iff_true, and_true] at h,
    exact h, },
  have := small.union h this,
  rw diff_union_self at this,
  exact (mk_litter_set L).not_lt (small.mono (subset_union_left _ _) this),
end

/-- To each litter we associate a subset which is to contain the atoms mapped outside it. -/
def mapped_outside_subset (L : litter) (B : extended_index δ) (h) : set atom :=
(le_mk_iff_exists_subset.mp
  (lt_of_lt_of_eq (mapped_outside_small M L B h) (mk_mapped_outside_domain M L B).symm).le).some

section
variables {M}

lemma mapped_outside_subset_spec (L : litter) (B : extended_index δ) (h) :
  mapped_outside_subset M L B h ⊆
  litter_set L \ {a : atom | (inl a, B) ∈ M} ∧
    #(mapped_outside_subset M L B h) = #{a : atom | mapped_outside M L B h a} :=
(le_mk_iff_exists_subset.mp
  (lt_of_lt_of_eq (mapped_outside_small M L B h)
    (mk_mapped_outside_domain M L B).symm).le).some_spec

lemma mapped_outside_subset_subset (L : litter) (B : extended_index δ) (h) :
  mapped_outside_subset M L B h ⊆ litter_set L :=
λ x hx, ((mapped_outside_subset_spec L B h).1 hx).1

lemma mapped_outside_subset_closure (L : litter) (B : extended_index δ) (h) :
  mapped_outside_subset M L B h ⊆ {a : atom | (inl a, B) ∈ M}ᶜ :=
λ x hx, ((mapped_outside_subset_spec L B h).1 hx).2

lemma mapped_outside_subset_small (L : litter) (B : extended_index δ) (h) :
  small (mapped_outside_subset M L B h) :=
lt_of_eq_of_lt (mapped_outside_subset_spec L B h).2
  (mapped_outside_small M L B h)

end

/-- A correspondence between the "mapped outside" subset of `L` and its atoms which were mapped
outside the target litter. We will use this equivalence to construct an approximation to
use in the freedom of action theorem. -/
@[irreducible] noncomputable def mapped_outside_equiv (L : litter) (B : extended_index δ) (h) :
  mapped_outside_subset M L B h ≃ {a : atom | mapped_outside M L B h a} :=
(cardinal.eq.mp (mapped_outside_subset_spec L B h).2).some

/-- The atom map we use for the approximation in the recursive invocation of the freedom of action
theorem. Note that at the moment, we can't really prove anything about this map, even its
injectivity, because that relies on properties of our hypothesis `H`. Instead, we defer the proofs
until after the main recursion of the freedom of action theorem has been wrapped up. -/
noncomputable def supported_action_atom_map_core (B : extended_index δ) (a : atom) : atom :=
if h : (inl a, B) ∈ M then
  M.atom_image a B h
else if h : a ∈ preimage_litter_subset M B then
  preimage_litter_equiv M B ⟨a, h⟩
else if h : ∃ L h, a ∈ mapped_outside_subset M L B h then
  mapped_outside_equiv M h.some B h.some_spec.some ⟨a, h.some_spec.some_spec⟩
else
  ⟨preimage_litter M B, arbitrary κ⟩

def supported_action_atom_map_core_domain (B : extended_index δ) : set atom :=
{a | (inl a, B) ∈ M} ∪ preimage_litter_subset M B ∪ ⋃ L h, mapped_outside_subset M L B h

lemma supported_action_atom_map_core_domain_small (B : extended_index δ) :
  small (supported_action_atom_map_core_domain M B) :=
begin
  refine small.union (small.union _ _) _,
  { refine lt_of_le_of_lt _ M.small,
    refine ⟨⟨λ a, ⟨_, a.prop⟩, λ a b h, _⟩⟩,
    simp only [subtype.mk_eq_mk, prod.mk.inj_iff, subtype.coe_inj, eq_self_iff_true, and_true] at h,
    exact h, },
  { exact preimage_litter_subset_small B, },
  { refine small.bUnion _ _,
    { refine lt_of_le_of_lt _ M.small,
      refine ⟨⟨λ L, ⟨_, L.prop⟩, λ L₁ L₂ h, _⟩⟩,
      simp only [subtype.mk_eq_mk, prod.mk.inj_iff, eq_self_iff_true, and_true,
        litter.to_near_litter_injective.eq_iff, subtype.coe_inj] at h,
      exact h, },
    { intros L hL,
      exact mapped_outside_subset_small L B hL, }, },
end

lemma mk_supported_action_atom_map_domain (B : extended_index δ) :
  #(supported_action_atom_map_core_domain M B ∆
    (supported_action_atom_map_core M B ''
      supported_action_atom_map_core_domain M B) : set atom) ≤
  #(litter_set $ sandbox_litter M B) :=
begin
  rw mk_litter_set,
  refine le_trans (mk_subtype_mono symm_diff_subset_union) (le_trans (mk_union_le _ _) _),
  refine add_le_of_le κ_regular.aleph_0_le _ _,
  exact le_of_lt (supported_action_atom_map_core_domain_small M B),
  exact le_trans mk_image_le (le_of_lt
    (supported_action_atom_map_core_domain_small M B)),
end

lemma supported_action_eq_of_mem_support_map {B : extended_index δ} {a : atom}
  (h : (inl a, B) ∈ M) : supported_action_atom_map_core M B a = M.atom_image a B h :=
by rw [supported_action_atom_map_core, dif_pos h]

lemma supported_action_eq_of_mem_preimage_litter_subset {B : extended_index δ} {a : atom}
  (h : a ∈ preimage_litter_subset M B) :
  supported_action_atom_map_core M B a = preimage_litter_equiv M B ⟨a, h⟩ :=
begin
  rw [supported_action_atom_map_core, dif_neg, dif_pos h],
  intro h',
  have := preimage_litter_not_banned M B,
  rw banned_litter_iff at this,
  push_neg at this,
  exact this.1 a h' (preimage_litter_subset_subset B h).symm,
end

lemma supported_action_eq_of_mem_mapped_outside_subset {B : extended_index δ} {a : atom}
  {L h} (h' : a ∈ mapped_outside_subset M L B h) :
  supported_action_atom_map_core M B a = mapped_outside_equiv M L B h ⟨a, h'⟩ :=
begin
  have : ∃ L h, a ∈ mapped_outside_subset M L B h := ⟨L, h, h'⟩,
  rw [supported_action_atom_map_core, dif_neg, dif_neg, dif_pos this],
  { cases eq_of_mem_litter_set_of_mem_litter_set
      (mapped_outside_subset_subset _ _ h h')
      (mapped_outside_subset_subset _ _ this.some_spec.some this.some_spec.some_spec),
    refl, },
  { intro h'',
    have := eq_of_mem_litter_set_of_mem_litter_set
      (mapped_outside_subset_subset _ _ h h')
      (preimage_litter_subset_subset _ h''),
    rw this at h,
    have := preimage_litter_not_banned M B,
    rw banned_litter_iff at this,
    push_neg at this,
    cases this.2.1 h, },
  { exact ((mapped_outside_subset_spec _ _ h).1 h').2, },
end

/-- Any atom in the image of the completed atom map is either in a banned litter, or it's being
mapped to an atom without preimage. -/
lemma banned_of_mem_supported_action_atom_map_core_domain (B : extended_index δ) (a : atom)
  (h : a ∈ supported_action_atom_map_core_domain M B) :
  banned_litter M B a.1 ∨ a ∈ preimage_litter_subset M B :=
begin
  obtain ((h | h) | h) := h,
  { exact or.inl (banned_litter.support_atom a h), },
  { exact or.inr h, },
  { simp only [mem_Union] at h,
    obtain ⟨L, hL, h⟩ := h,
    have := mapped_outside_subset_subset L B hL h,
    rw mem_litter_set at this,
    rw this,
    exact or.inl (banned_litter.support_litter L hL), },
end

/-- Any atom in the image of the completed atom map is in a banned litter. -/
lemma banned_of_mem_image_supported_action_atom_map_core_domain (B : extended_index δ) (a : atom)
  (h : a ∈ supported_action_atom_map_core M B ''
    supported_action_atom_map_core_domain M B) :
  banned_litter M B a.1 :=
begin
  obtain ⟨a, h, rfl⟩ := h,
  rw supported_action_atom_map_core,
  split_ifs with h₁ h₂ h₃,
  { exact (banned_litter.map_atom _ _), },
  { obtain ⟨L, hL₁, hL₂⟩ := (preimage_litter_equiv M B ⟨a, h₂⟩).prop.mem_map,
    rw mem_litter_set at hL₂,
    rw hL₂,
    exact (banned_litter.map_litter _ _), },
  { refine (banned_litter.map_diff _ h₃.some_spec.some _ _),
    exact ⟨(mapped_outside_equiv M h₃.some B h₃.some_spec.some
        ⟨a, h₃.some_spec.some_spec⟩).prop.mem_map,
      (mapped_outside_equiv M h₃.some B h₃.some_spec.some
        ⟨a, h₃.some_spec.some_spec⟩).prop.not_mem_map⟩, },
  { obtain ((h | h) | h) := h,
    cases h₁ h,
    cases h₂ h,
    simp only [mem_Union] at h,
    cases h₃ h, },
end

lemma supported_action_atom_map_domain_disjoint (B : extended_index δ) :
  disjoint (supported_action_atom_map_core_domain M B ∪
      supported_action_atom_map_core M B ''
        supported_action_atom_map_core_domain M B)
  (litter_set (sandbox_litter M B)) :=
begin
  rw [disjoint_iff_inter_eq_empty, eq_empty_iff_forall_not_mem],
  rintros a ⟨ha₁, ha₂⟩,
  rw mem_litter_set at ha₂,
  have hnb := sandbox_litter_not_banned M B,
  rw ← ha₂ at hnb,
  cases ha₁,
  { cases banned_of_mem_supported_action_atom_map_core_domain M B a ha₁,
    { exact hnb h, },
    { have := preimage_litter_subset_subset B h,
      rw [mem_litter_set, ha₂] at this,
      exact sandbox_litter_ne_preimage_litter M B this, }, },
  { exact hnb (banned_of_mem_image_supported_action_atom_map_core_domain M B a ha₁), },
end

structure support_map.injective (B : extended_index δ) : Prop :=
(atom_injective : ∀ ⦃a b⦄ ha hb, M.atom_image a B ha = M.atom_image b B hb → a = b)
(near_litter_injective : ∀ ⦃L₁ L₂ : litter⦄ hL₁ hL₂,
  ((M.near_litter_image L₁.to_near_litter B hL₁ : set atom) ∩
    (M.near_litter_image L₂.to_near_litter B hL₂)).nonempty → L₁ = L₂)

lemma support_map.injective.le {B : extended_index δ} {S T : support_map δ}
  (hS : S.injective B) (hT : T ≤ S) : T.injective B :=
begin
  refine ⟨λ a b ha hb h, _, λ L₁ L₂ hL₁ hL₂ h, _⟩,
  { exact hS.atom_injective (hT.carrier_subset ha) (hT.carrier_subset hb)
      (((hT.map_atom ha).symm.trans h).trans (hT.map_atom hb)), },
  { refine hS.near_litter_injective (hT.carrier_subset hL₁) (hT.carrier_subset hL₂) _,
    rwa [← hT.map_near_litter hL₁, ← hT.map_near_litter hL₂], },
end

lemma supported_action_inj_on (B : extended_index δ) (hM : M.injective B) :
  inj_on (supported_action_atom_map_core M B) (supported_action_atom_map_core_domain M B) :=
begin
  rintros a ((ha | ha) | ⟨_, ⟨L, rfl⟩, ⟨_, ⟨hL, rfl⟩, ha⟩⟩)
    b ((hb | hb) | ⟨_, ⟨L', rfl⟩, ⟨_, ⟨hL', rfl⟩, hb⟩⟩) hab,
  { rw [supported_action_eq_of_mem_support_map _ ha,
      supported_action_eq_of_mem_support_map _ hb] at hab,
    exact hM.atom_injective ha hb hab, },
  { rw [supported_action_eq_of_mem_support_map _ ha,
      supported_action_eq_of_mem_preimage_litter_subset _ hb] at hab,
    obtain ⟨hab, -⟩ := subtype.coe_eq_iff.mp hab.symm,
    cases hab.not_mem_domain a ha rfl, },
  { rw [supported_action_eq_of_mem_support_map _ ha,
      supported_action_eq_of_mem_mapped_outside_subset _ hb] at hab,
    obtain ⟨hab, -⟩ := subtype.coe_eq_iff.mp hab.symm,
    cases hab.not_mem_domain a ha rfl, },
  { rw [supported_action_eq_of_mem_preimage_litter_subset _ ha,
      supported_action_eq_of_mem_support_map _ hb] at hab,
    obtain ⟨hab, -⟩ := subtype.coe_eq_iff.mp hab,
    cases hab.not_mem_domain b hb rfl, },
  { rw [supported_action_eq_of_mem_preimage_litter_subset _ ha,
      supported_action_eq_of_mem_preimage_litter_subset _ hb,
      subtype.coe_inj, embedding_like.apply_eq_iff_eq] at hab,
    exact subtype.coe_inj.mpr hab, },
  { rw [supported_action_eq_of_mem_preimage_litter_subset _ ha,
      supported_action_eq_of_mem_mapped_outside_subset _ hb] at hab,
    obtain ⟨hab, -⟩ := subtype.coe_eq_iff.mp hab,
    cases without_preimage.not_mapped_outside hab _ hL'
      (mapped_outside_equiv M L' B hL' ⟨b, hb⟩).prop, },
  { rw [supported_action_eq_of_mem_mapped_outside_subset _ ha,
      supported_action_eq_of_mem_support_map _ hb] at hab,
    obtain ⟨hab, -⟩ := subtype.coe_eq_iff.mp hab,
    cases hab.not_mem_domain b hb rfl, },
  { rw [supported_action_eq_of_mem_mapped_outside_subset _ ha,
      supported_action_eq_of_mem_preimage_litter_subset _ hb] at hab,
    obtain ⟨hab, -⟩ := subtype.coe_eq_iff.mp hab.symm,
    cases without_preimage.not_mapped_outside hab _ hL
      (mapped_outside_equiv M L B hL ⟨a, ha⟩).prop, },
  { rw [supported_action_eq_of_mem_mapped_outside_subset _ ha,
      supported_action_eq_of_mem_mapped_outside_subset _ hb] at hab,
    cases hM.near_litter_injective hL hL' _,
    { simp only [subtype.coe_inj, embedding_like.apply_eq_iff_eq] at hab,
      exact hab, },
    obtain ⟨hab, -⟩ := subtype.coe_eq_iff.mp hab,
    exact ⟨_, hab.1, (mapped_outside_equiv M L' B hL' ⟨b, hb⟩).prop.1⟩, },
end

/-- We can't prove `h` without knowing facts about the hypothesis `H`. We defer this proof to later,
at which point we will know many facts about the hypothesis. -/
noncomputable def supported_action_atom_map (B : extended_index δ) : local_perm atom :=
if h : M.injective B then
  local_perm.complete
    (supported_action_atom_map_core M B)
    (supported_action_atom_map_core_domain M B)
    (litter_set $ sandbox_litter M B)
    (mk_supported_action_atom_map_domain M B)
    (le_of_le_of_eq κ_regular.aleph_0_le (mk_litter_set _).symm)
    (supported_action_atom_map_domain_disjoint M B)
    (supported_action_inj_on M B h)
else
  local_perm.of_set ∅

lemma sandbox_subset_small (B : extended_index δ) : small (local_perm.sandbox_subset
  (mk_supported_action_atom_map_domain M B)
  (le_of_le_of_eq κ_regular.aleph_0_le (mk_litter_set _).symm)) :=
begin
  rw small,
  rw cardinal.mk_congr (local_perm.sandbox_subset_equiv _ _),
  simp only [mk_sum, mk_prod, mk_denumerable, lift_aleph_0, lift_uzero, lift_id],
  refine add_lt_of_lt κ_regular.aleph_0_le _ _;
    refine (mul_lt_of_lt κ_regular.aleph_0_le (lt_of_le_of_lt Λ_limit.aleph_0_le Λ_lt_κ) _);
    refine lt_of_le_of_lt (mk_subtype_mono (diff_subset _ _)) _,
  { exact supported_action_atom_map_core_domain_small M B, },
  { exact lt_of_le_of_lt mk_image_le
      (supported_action_atom_map_core_domain_small M B), },
end

lemma supported_action_atom_map_domain (B : extended_index δ) :
  (supported_action_atom_map M B).domain ⊆
    (supported_action_atom_map_core_domain M B) ∪
    (supported_action_atom_map_core M B ''
      supported_action_atom_map_core_domain M B) ∪
    (local_perm.sandbox_subset
      (mk_supported_action_atom_map_domain M B)
      (le_of_le_of_eq κ_regular.aleph_0_le (mk_litter_set _).symm)) :=
begin
  rw supported_action_atom_map,
  split_ifs,
  { refl, },
  { exact empty_subset _, },
end

lemma supported_action_atom_map_domain_small (B : extended_index δ) :
  small (supported_action_atom_map M B).domain :=
small.mono (supported_action_atom_map_domain M B)
  (small.union (small.union
      (supported_action_atom_map_core_domain_small M B)
      (lt_of_le_of_lt mk_image_le
        (supported_action_atom_map_core_domain_small M B)))
    (sandbox_subset_small M B))

noncomputable def supported_action_index (π : near_litter_approx) (B : extended_index δ) :
  near_litter_approx := {
  atom_perm := supported_action_atom_map M B,
  litter_perm := π.flexible_completion_litter_perm α B,
  domain_small := λ L, small.mono (inter_subset_right _ _)
    (supported_action_atom_map_domain_small M B),
}

noncomputable def supported_action (π : struct_approx δ) : struct_approx δ :=
λ B, supported_action_index M (π B) B

lemma supported_action_smul_atom_eq (π : struct_approx δ) (a : atom) (B : extended_index δ)
  (ha : (inl a, B) ∈ M) (hM : M.injective B) :
  supported_action M π B • a = M.atom_image a B ha :=
begin
  dsimp only [supported_action, supported_action_index, supported_action_atom_map,
    ← near_litter_approx.smul_atom_eq],
  rw [dif_pos hM, local_perm.complete_apply_eq, supported_action_atom_map_core, dif_pos ha],
  exact or.inl (or.inl ha),
end

lemma supported_action_smul_litter_eq (π : struct_approx δ) (L : litter) (B : extended_index δ) :
  supported_action M π B • L = (π B).flexible_completion_litter_perm α B L := rfl

lemma supported_action_atom_perm_domain_eq {π : struct_approx δ}
  {B : extended_index δ} (hM : M.injective B) :
    (supported_action M π B).atom_perm.domain =
    local_perm.complete_domain
      (mk_supported_action_atom_map_domain M B)
    (le_of_le_of_eq κ_regular.aleph_0_le (mk_litter_set _).symm) :=
begin
  dsimp only [supported_action, supported_action_index, supported_action_atom_map],
  rw dif_pos hM,
  refl,
end

end struct_approx

end con_nf
