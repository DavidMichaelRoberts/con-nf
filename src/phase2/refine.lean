import phase2.struct_action
import phase2.fill_atom_range
import phase2.fill_atom_orbits

universe u

namespace con_nf
variables [params.{u}]

/-!
# Refinements of actions
-/

namespace near_litter_action

variables (φ : near_litter_action) (hφ : φ.lawful)

noncomputable def refine (hφ : φ.lawful) : near_litter_action :=
φ.fill_atom_range.fill_atom_orbits (φ.fill_atom_range_lawful hφ)

variables {φ} {hφ}

@[simp] lemma refine_atom_map {a : atom} (ha : (φ.atom_map a).dom) :
  (φ.refine hφ).atom_map a = φ.atom_map a :=
begin
  unfold refine,
  refine part.ext' _ _,
  { simp only [ha, fill_atom_orbits_atom_map, orbit_atom_map_dom_iff, fill_atom_range_atom_map,
      iff_true],
    exact or.inl (or.inl ha), },
  intros h₁ h₂,
  refine (φ.fill_atom_range.orbit_atom_map_eq_of_mem_dom _ _ (or.inl ha)).trans _,
  exact φ.supported_action_eq_of_dom ha,
end

@[simp] lemma refine_atom_map_get {a : atom} (ha : (φ.atom_map a).dom) :
  ((φ.refine hφ).atom_map a).get (or.inl (or.inl ha)) = (φ.atom_map a).get ha :=
by simp only [refine_atom_map ha]

@[simp] lemma refine_litter_map : (φ.refine hφ).litter_map = φ.litter_map := rfl

lemma refine_precise : precise (φ.refine hφ) :=
fill_atom_orbits_precise _ (fill_atom_range_symm_diff_subset_ran hφ)

end near_litter_action

namespace struct_action

variables {β : type_index} (φ : struct_action β) (hφ : φ.lawful)

noncomputable def refine : struct_action β := λ A, (φ A).refine (hφ A)

@[simp] lemma refine_apply {A : extended_index β} :
  φ.refine hφ A = (φ A).refine (hφ A) := rfl

@[simp] lemma refine_atom_map {A : extended_index β} {a : atom} (ha : ((φ A).atom_map a).dom) :
  ((φ A).refine (hφ A)).atom_map a = (φ A).atom_map a := near_litter_action.refine_atom_map ha

-- TODO: check confluence with previous lemma
@[simp] lemma refine_atom_map_get {A : extended_index β} {a : atom} (ha : ((φ A).atom_map a).dom) :
  (((φ A).refine (hφ A)).atom_map a).get (or.inl (or.inl ha)) = ((φ A).atom_map a).get ha :=
near_litter_action.refine_atom_map_get ha

@[simp] lemma refine_litter_map {A : extended_index β} :
  ((φ A).refine (hφ A)).litter_map = (φ A).litter_map := rfl

lemma refine_precise : precise (φ.refine hφ) :=
λ A, near_litter_action.refine_precise

end struct_action

end con_nf
