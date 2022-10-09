import phase2.freedom_of_action.allowable

/-!
# Applying Zorn's lemma

We define a preorder on partial allowable permutations.
`σ ≤ ρ` (written `σ ⊑ ρ` in the blueprint) means:

* `σ` is a subset of `ρ`;
* if `ρ` has any new `A`-flexible litter, then it has all (in both domain and range);
* within each litter, if `ρ.domain` has any new atom, then it must have all
    atoms in that litter (and hence must also have the litter), and dually for the range.

Note that the second condition is exactly the condition in `spec.flex_cond.all`.

To prove that Zorn's lemma can be applied, we must show that for any chain `c` of allowable
partial permutations, the union of the specifications in the chain is allowable, and carefully
extends every element of the chain.

The non-trivial part of this proof is the "small or all" conditions for atoms and flexible litters.
Due to the particular construction of the preorder `≤`, if we add any atom (resp. flexible litter),
we must add all of them.
-/

open set sum

universe u

namespace con_nf
namespace allowable_spec

variables [params.{u}] {α : Λ} [phase_2_core_assumptions α] [phase_2_positioned_assumptions α]
  [typed_positions.{}] [phase_2_assumptions α] {B : le_index α}

open spec

structure perm_le (σ ρ : allowable_spec B) : Prop :=
(le : (σ : spec B) ≤ (ρ : spec B))
(all_flex_domain (L : litter) (N : near_litter) (A : extended_index B) (hL : flex L A)
  (hσ : (⟨inr ⟨L.to_near_litter, N⟩, A⟩ : binary_condition B) ∉ (σ : spec B))
  (hρ : (⟨inr ⟨L.to_near_litter, N⟩, A⟩ : binary_condition B) ∈ (ρ : spec B)) :
  (∀ L', flex L' A →
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ (ρ : spec B).domain ∧
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ (ρ : spec B).range))
(all_flex_range (L : litter) (N : near_litter) (A : extended_index B) (hL : flex L A)
  (hσ : (⟨inr ⟨N, L.to_near_litter⟩, A⟩ : binary_condition B) ∉ (σ : spec B))
  (hρ : (⟨inr ⟨N, L.to_near_litter⟩, A⟩ : binary_condition B) ∈ (ρ : spec B)) :
  (∀ L', flex L' A →
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ (ρ : spec B).domain ∧
    (⟨inr L'.to_near_litter, A⟩ : support_condition B) ∈ (ρ : spec B).range))
(all_atoms_domain (a b : atom) (L : litter) (ha : a ∈ litter_set L) (A : extended_index B)
  (hσ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∉ (σ : spec B))
  (hρ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∈ (ρ : spec B)) :
  ∀ c ∈ litter_set L, ∃ d, (⟨inl ⟨c, d⟩, A⟩ : binary_condition B) ∈ (ρ : spec B))
(all_atoms_range (a b : atom) (L : litter) (ha : b ∈ litter_set L) (A : extended_index B)
  (hσ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∉ (σ : spec B))
  (hρ : (⟨inl ⟨a, b⟩, A⟩ : binary_condition B) ∈ (ρ : spec B)) :
  ∀ c ∈ litter_set L, ∃ d, (⟨inl ⟨d, c⟩, A⟩ : binary_condition B) ∈ (ρ : spec B))

instance has_le : has_le (allowable_spec B) := ⟨perm_le⟩

/-! We now prove that the claimed preorder really is a preorder. -/

lemma extends_refl (σ : allowable_spec B) : σ ≤ σ :=
⟨subset.rfl,
  λ _ _ _ _ h1 h2, by cases h1 h2,
  λ _ _ _ _ h1 h2, by cases h1 h2,
  λ _ _ _ _ _ h1 h2, by cases h1 h2,
  λ _ _ _ _ _ h1 h2, by cases h1 h2⟩

lemma extends_trans (ρ σ τ : allowable_spec B) (h₁ : ρ ≤ σ) (h₂ : σ ≤ τ) : ρ ≤ τ :=
begin
  obtain ⟨hsub, hflx_domain, hflx_range, hatom_domain, hatom_range⟩ := h₁,
  obtain ⟨hsub', hflx_domain', hflx_range', hatom_domain', hatom_range'⟩ := h₂,
  refine ⟨hsub.trans hsub', λ L N A hLA hnin hin, _, λ L N A hLA hnin hin, _,
    λ a b L hab A hnin hin, _, λ a b L hab A hnin hin, _⟩,
  { by_cases (inr (L.to_near_litter, N), A) ∈ (σ : spec B),
    { intros l hla,
      have := hflx_domain L N A hLA hnin h l hla,
      rw [spec.mem_domain, spec.mem_range] at this ⊢,
      obtain ⟨⟨b, hb, hdom⟩, ⟨c, hc, hrge⟩⟩ := this,
      exact ⟨⟨b, hsub' hb, hdom⟩, ⟨c, hsub' hc, hrge⟩⟩ },
    { exact hflx_domain' L N A hLA h hin } },
  { by_cases (inr (N, L.to_near_litter), A) ∈ (σ : spec B),
    { intros l hla,
      have := hflx_range L N A hLA hnin h l hla,
      rw [spec.mem_domain, spec.mem_range] at this ⊢,
      obtain ⟨⟨b, hb, hdom⟩, ⟨c, hc, hrge⟩⟩ := this,
      exact ⟨⟨b, hsub' hb, hdom⟩, ⟨c, hsub' hc, hrge⟩⟩ },
    { exact hflx_range' L N A hLA h hin } },
  { by_cases (inl (a, b), A) ∈ (σ : spec B),
    { intros c hc,
      obtain ⟨d, hd⟩ := hatom_domain a b L hab A hnin h c hc,
      exact ⟨d, hsub' hd⟩ },
    { exact hatom_domain' a b L hab A h hin } },
  { by_cases (inl (a, b), A) ∈ (σ : spec B),
    { intros c hc,
      obtain ⟨d, hd⟩ := hatom_range a b L hab A hnin h c hc,
      refine ⟨d, hsub' hd⟩ },
    { exact hatom_range' a b L hab A h hin } }
end

instance : preorder (allowable_spec B) :=
{ le := perm_le,
  le_refl := extends_refl,
  le_trans := extends_trans }

lemma domain_subset_of_le {σ τ : allowable_spec B} (hστ : σ ≤ τ) :
  (σ : spec B).domain ⊆ (τ : spec B).domain :=
begin
  rintro x hx,
  rw spec.mem_domain at hx ⊢,
  obtain ⟨b, hb, hdom⟩ := hx,
  exact ⟨b, hστ.le hb, hdom⟩,
end
lemma range_subset_of_le {σ τ : allowable_spec B} (hστ : σ ≤ τ) :
  (σ : spec B).range ⊆ (τ : spec B).range :=
begin
  rintro x hx,
  rw spec.mem_range at hx ⊢,
  obtain ⟨b, hb, hdom⟩ := hx,
  exact ⟨b, hστ.le hb, hdom⟩,
end

/-- A condition required later. -/
lemma inv_mono : monotone (@has_inv.inv (allowable_spec B) _) :=
begin
  rintro σ τ ⟨h1, h2, h3, h4, h5⟩,
  refine ⟨λ x h, h1 h,
          λ L N hLA hnin hin L' A' hLA', _,
          λ L N hLA hnin hin L' A' hLA', _,
          λ a b, h5 b a, λ a b, h4 b a⟩; rw [coe_inv, spec.domain_inv, spec.range_inv],
  exacts [(h3 L N hLA hnin hin L' A' hLA').symm, (h2 L N hLA hnin hin L' A' hLA').symm],
end

@[simp] lemma inv_le_inv (σ τ : allowable_spec B) : σ⁻¹ ≤ τ⁻¹ ↔ σ ≤ τ :=
⟨λ h, by simpa only [inv_inv] using inv_mono h, λ h, inv_mono h⟩

section zorn_setup

/-! To set up for Zorn's lemma, we need to show that the union of all allowable partial permutations
in a chain is an upper bound for the chain. In particular, we first show that it is allowable, and
then we show it extends all elements in the chain.

Non-trivial bit: the "small or all" conditions — these are enforced by the "if adding any, add all"
parts of the definition of ≤. -/

variables {c : set (allowable_spec B)}

lemma is_subset_chain_of_is_chain : is_chain (≤) c → is_chain (≤) (subtype.val '' c) :=
is_chain.image _ _ _ $ λ _ _, perm_le.le

lemma one_to_one_Union (hc : is_chain (≤) c) : spec.one_to_one_forward (⨆ σ ∈ c, ↑σ : spec B) :=
begin
  refine λ A, ⟨_, _⟩,
  all_goals
  { simp_rw mem_supr,
    rintro b x ⟨σx, hσx, hx⟩ y ⟨σy, hσy, hy⟩,
    obtain hxy | rfl := ne_or_eq σx σy,
    cases hc hσx hσy hxy,
    have hx' := h.le hx,
    swap,
    have hy' := h.le hy },
  -- Note: there must be a better way of doing this below.
  exact (σx.2.forward.one_to_one A).atom b hx hy',
  exact (σy.2.forward.one_to_one A).atom b hx' hy,
  exact (σx.2.forward.one_to_one A).atom b hx hy,
  exact (σx.2.forward.one_to_one A).near_litter b hx hy',
  exact (σy.2.forward.one_to_one A).near_litter b hx' hy,
  exact (σx.2.forward.one_to_one A).near_litter b hx hy,
end


lemma useful_lemma {a' b: atom} {τ : spec ↑B} {A : extended_index ↑B} {L : litter} {N': near_litter}
  (hτ : spec.allowable B τ) (hτa' : (sum.inl (a', b), A) ∈ τ) (hb : b ∈ N')
  (hN : (inr (L.to_near_litter, N'), A) ∈ τ) : a' ∈ litter_set L :=
begin
  have hτa := hτa',
  obtain ⟨M, ⟨hM, ⟨M_symm_diff, hM2,hM3⟩ ⟩ ⟩ := hτ.backward.near_litter_cond N' L.to_near_litter A hN,
  simp only [subtype.coe_mk, spec.mem_inv, inv_mk, prod.swap_prod_mk] at hM2,
  dsimp [litter.to_near_litter] at hM3,
  rw [hM3, symm_diff_def],
  have ha2 : b∈ litter_set N'.fst → a' ∉ range M_symm_diff,
  { intro hz,
    by_contra ha2,
    simp only [set.mem_range, set_coe.exists] at ha2,
    obtain ⟨z_2, hz_2, hz_2_2⟩ := ha2,
    have := hM2 ⟨z_2, hz_2⟩,
    rw hz_2_2 at this,
    have := (hτ.backward.one_to_one A).atom _ this hτa,
    subst this,
    cases hz_2,
    exact (set.not_mem_of_mem_diff hz_2) hb,
    exact (set.not_mem_of_mem_diff hz_2) hz },
  by_cases ha: a' ∈ M,
  { obtain ⟨L', hL, atom_map, hall, hall2⟩ | ⟨ha, hL, hsmall_out⟩ | ⟨L', hL, hsmall_in, hsmall_in2⟩ :=
      hτ.backward.atom_cond N'.fst A,
    { have ha0 := ha,
      have := (hτ.forward.one_to_one A).near_litter _ hM hL,
      simp only at this,
      subst this,
      rw [←set_like.mem_coe, hall2] at ha,
      simp only [set.mem_range, set_coe.exists] at ha,
      obtain ⟨z, hz, hz2⟩ := ha,
      have := hall z hz,
      rw hz2 at this,
      have := (hτ.backward.one_to_one A).atom _ this hτa,
      subst this,
      exact or.inl ⟨ha0, ha2 hz⟩ },
    { simp only [domain_inv, spec.mem_range, not_exists, not_and] at ha,
      have := ha _ hM,
      simp only [binary_condition.inv_def, map_inr, prod.swap_prod_mk, binary_condition.range_mk,
        eq_self_iff_true, not_true] at this,
      cases this },
    { have := (hτ.forward.one_to_one A).near_litter _ hM hL, simp only at this, subst this,
      exact or.inl ⟨ha, ha2 $ (hsmall_in2 hτa).mpr ha⟩ } },

  by_cases hb2 :  a' ∈ range M_symm_diff,
  { exact or.inr ⟨hb2, ha⟩ },
  have hb3 : b∈ litter_set N'.fst,
  { by_contra hb3,
    have := (hτ.forward.one_to_one A).atom _ (hM2 ⟨ b, (or.inr ⟨hb, hb3⟩)⟩) hτa,
    exact hb2 ⟨_, this⟩ },
  exfalso,
  obtain ⟨L', hL, atom_map, hall, hall2⟩ | ⟨ha, hL, hsmall_out⟩ | ⟨L', hL, hsmall_in, hsmall_in2⟩ :=
    hτ.backward.atom_cond N'.fst A,
  { have := (hτ.forward.one_to_one A).near_litter _ hM hL,
    simp only at this,
    subst this,
    have := (hτ.forward.one_to_one A).atom _ (hall b hb3) hτa,
    subst this,
    rw [←set_like.mem_coe, hall2] at ha,
    simpa only [mem_range_self, not_true] using ha },
  { simp only [domain_inv, spec.mem_range, not_exists, not_and] at ha,
    simpa only [binary_condition.inv_def, map_inr, prod.swap_prod_mk,
      binary_condition.range_mk, eq_self_iff_true, not_true] using ha _ hM },
  { have := (hτ.forward.one_to_one A).near_litter _ hM hL,
    simp only at this,
    subst this,
    exact ha ((hsmall_in2 hτa).mp hb3) }
end

lemma atom_cond_Union (hc : is_chain (≤) c) (L A) : spec.atom_cond (⨆ σ ∈ c, ↑σ : spec B) L A :=
begin
  obtain rfl | ⟨⟨σ, hσ₁⟩, hσ₂⟩ := c.eq_empty_or_nonempty,
  { refine spec.atom_cond.small_out _ _,
    { simp only [not_mem_empty, supr_false, supr_bot, domain_bot, not_false_iff] },
    { simp only [not_mem_empty, spec.domain_bot, sep_false, small_empty, supr_false, supr_bot] } },
  by_cases h' : ∃ (ρ : allowable_spec B) (hρ : ρ ∈ c) (τ : allowable_spec B)
      (hτ : τ ∈ c) a b (ha : a ∈ litter_set L),
      (inl (a, b), A) ∉ (ρ : spec B) ∧ (inl (a, b), A) ∈ (τ : spec B) ∧ ρ ≤ τ,
  { obtain ⟨ρ, hρ, τ, hτ, a, b, ha, Hρ, Hτ, hρτ⟩ := h',
    obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, h₁, h₂, h₃⟩ := τ.prop.forward.atom_cond L A,
    { refine spec.atom_cond.all N _ atom_map _ h₃; simp_rw mem_supr,
      { exact ⟨_, hτ, h₁⟩ },
      { exact λ a' ha', ⟨_, hτ, h₂ _ ha'⟩ } },
    all_goals
    { cases h₂.lt.ne _,
      rw ← mk_litter_set L, convert rfl,
      ext a',
      refine (and_iff_left_of_imp $ λ ha', _).symm,
      cases hρτ.all_atoms_domain a b L ha A Hρ Hτ a' ha' with d hd,
      exact mem_domain.2 ⟨_, hd, rfl⟩ } },
  push_neg at h',
  have H' : ∀ (ρ : allowable_spec B), ρ ∈ c → ∀ (τ : allowable_spec B),
              τ ∈ c → ∀ (a b : atom), a ∈ litter_set L →
              (inl (a, b), A) ∈ (ρ : spec B) → (inl (a, b), A) ∈ (τ : spec B),
  { refine λ ρ hρ τ hτ a b ha Hρ, of_not_not (λ Hτ, _),
    cases h' τ hτ ρ hρ a b ha Hτ Hρ ((hc hτ hρ _).elim id $ λ h, _),
    { rintro rfl,
      exact Hτ Hρ },
    { cases Hτ (h.1 Hρ) } },
  have : {a ∈ litter_set L | (inl a, A) ∈ (⨆ σ ∈ c, ↑σ : spec B).domain}
          = {a ∈ litter_set L | (inl a, A) ∈ σ.domain},
  { ext a,
    simp_rw [mem_sep_iff, mem_domain, mem_supr],
    refine and_congr_right (λ ha, ⟨_, _⟩),
    { rintro ⟨⟨⟨a', b⟩ | _, C⟩, ⟨ρ, hρ, hb⟩, ⟨⟩⟩,
      exact ⟨_, H' ρ hρ _ hσ₂ a b ha hb, rfl⟩ },
    { exact λ ⟨b, hbσ, hba⟩, ⟨b, ⟨⟨σ, hσ₁⟩, hσ₂, hbσ⟩, hba⟩ } },
  obtain ⟨N, h₁, atom_map, h₂, h₃⟩ | ⟨h₁, h₂⟩ | ⟨N, hN, h₁, h₂⟩ := hσ₁.forward.atom_cond L A,
  { refine spec.atom_cond.all N _ atom_map (λ a' ha', _) h₃; simp_rw mem_supr,
    exacts [⟨_, hσ₂, h₁⟩, ⟨_, hσ₂, h₂ _ ha'⟩] },
  { by_cases (inr L.to_near_litter, A) ∈ (⨆ σ ∈ c, ↑σ : spec B).domain,
    { rw mem_domain at h,
      obtain ⟨⟨_ | ⟨N₁, N₂⟩, C⟩, hc₁, ⟨⟩⟩ := h,
      refine spec.atom_cond.small_in N₂ hc₁ (by rwa this) _,
      simp_rw mem_supr at ⊢ hc₁,
      rintro a' b ⟨⟨τ, hτ⟩, hτc, hτa'⟩,
      obtain ⟨⟨ρ, hρ⟩, hρc, hρN₂⟩ := hc₁,
      obtain ⟨N', h₁', atom_map', h₂', h₃'⟩ | ⟨h₁', h₂'⟩ | ⟨N', hN', h₁', h₂'⟩ :=
        hρ.forward.atom_cond L A,
      { rw [(hρ.backward.one_to_one A).near_litter _ hρN₂ h₁', ←set_like.mem_coe, h₃'],
        refine ⟨λ ha', ⟨⟨a', ha'⟩,
            (hτ.backward.one_to_one A).atom _ (H' _ hρc _ hτc _ _ ha' (h₂' a' ha')) hτa'⟩, _⟩,
        rintro ⟨⟨b', hb'⟩, rfl⟩,
        have := (hτ.forward.one_to_one A).atom _ (H' _ hρc _ hτc _ _ hb' (h₂' b' hb')) hτa',
        rwa this at hb' },
      { cases h₁' (mem_domain.2 ⟨_, hρN₂, rfl⟩) },
      rw [(hρ.backward.one_to_one A).near_litter _ hρN₂ hN'],
      refine ⟨λ ha', (h₂' $ H' _ hτc _ hρc _ _ ha' hτa').1 ha', λ hb, _⟩,
      have : (@has_le.le (allowable_spec B) allowable_spec.has_le ⟨τ, hτ⟩ ⟨ρ, hρ⟩) → a' ∈ litter_set L,
      { exact λ h, (h₂' (h.le hτa')).mpr hb },
      by_cases h_eq : (⟨τ, hτ⟩ : allowable_spec B) = ⟨ρ, hρ⟩,
      { exact this h_eq.le },
      have hchain := hc hτc hρc h_eq,
      cases hchain,
      exact this hchain,
      exact useful_lemma hτ hτa' hb (hchain.le hN') },
    { exact spec.atom_cond.small_out h (by rwa this) } },
  { refine spec.atom_cond.small_in N _ _ _; simp only [domain_supr, mem_supr],
    { exact ⟨_, hσ₂, hN⟩ },
    { simp_rw ←domain_supr,
      rwa this },
    rintro a' b ⟨⟨τ, hτ⟩, hτc, hτa'⟩,
    refine ⟨λ ha', (h₂ $ H' _ hτc _ hσ₂ a' b ha' hτa').1 ha', λ hb, _⟩,
    have : (@has_le.le (allowable_spec B) allowable_spec.has_le ⟨τ, hτ⟩ ⟨σ, hσ₁⟩) → a' ∈ litter_set L,
    {intro h, have := (h.le hτa'), exact (h₂ this).mpr hb},
    by_cases h_eq :(⟨τ, hτ⟩ : allowable_spec B) = ⟨σ, hσ₁⟩,
    exact this (le_of_eq h_eq),
    have hchain := hc hτc hσ₂ h_eq,
    cases hchain,
    exact this hchain,
    have := hchain.le hN,
    exact useful_lemma hτ hτa' hb this }
end


lemma near_litter_cond_Union (hc : is_chain (≤) c) (N₁ N₂ A) :
  (⨆ σ ∈ c, ↑σ : spec B).near_litter_cond N₁ N₂ A :=
begin
  simp_rw [near_litter_cond, mem_supr],
  rintro ⟨σ, hσ, hρ⟩,
  obtain ⟨M, hM, f, h1, h2⟩ := σ.prop.forward.near_litter_cond N₁ N₂ A hρ,
  exact ⟨M, ⟨σ, hσ, hM⟩, f, λ a, ⟨σ, hσ, h1 a⟩, h2⟩,
end

lemma flex_cond_Union (hc : is_chain (≤) c) (C : extended_index B) :
  (⨆ σ ∈ c, ↑σ : spec B).flex_cond B C :=
begin
  obtain rfl | ⟨⟨σ, hσ₁⟩, hσ₂⟩ := c.eq_empty_or_nonempty,
  { refine spec.flex_cond.co_large _ _;
      simp only [spec.range_bot, coe_set_of, supr_false, supr_bot, not_mem_empty, not_false_iff,
        and_true, mk_flex_litters, domain_bot, not_false_iff, and_true, mk_flex_litters] },
  by_cases h : ∃ (ρ : allowable_spec B) (hρ : ρ ∈ c) (τ : allowable_spec B) (hτ : τ ∈ c) L
    (hL : flex L C),
    (((inr L.to_near_litter, C) ∉ (ρ : spec B).domain ∧
      (inr L.to_near_litter, C) ∈ (τ : spec B).domain) ∨
      ((inr L.to_near_litter, C) ∉ (ρ : spec B).range ∧
      (inr L.to_near_litter, C) ∈ (τ : spec B).range)) ∧ ρ ≤ τ,
  { obtain ⟨ρ, hρ, τ, hτ, L, hL, ⟨h, hρτ⟩⟩ := h,
    have H : ∀ L', flex L' C →
        (⟨inr L'.to_near_litter, C⟩ : support_condition B) ∈ (τ : spec B).domain ∧
        (⟨inr L'.to_near_litter, C⟩ : support_condition B) ∈ (τ : spec B).range,
    { simp_rw [mem_domain, spec.mem_range] at h,
      obtain ⟨Hρ, ⟨⟨_ | ⟨N₁, N₂⟩, _⟩, hb₁, hb₂⟩⟩ | ⟨Hρ, ⟨⟨_ | ⟨N₁, N₂⟩, _⟩, hb₁, hb₂⟩⟩ := h;
      cases hb₂,
      { exact hρτ.all_flex_domain L N₂ C hL (λ Hρ', Hρ ⟨_, Hρ', rfl⟩) hb₁ },
      { exact hρτ.all_flex_range L N₁ C hL (λ Hρ', Hρ ⟨_, Hρ', rfl⟩) hb₁ } },
    refine spec.flex_cond.all _ _;
    intros L' hL';
    obtain ⟨H₁, H₂⟩ := H L' hL';
    simp only [spec.domain_supr, spec.range_supr];
    exact mem_Union₂_of_mem hτ ‹_› },
  push_neg at h,
  have := hσ₁.flex_cond C,
  have H : ∀ (ρ : allowable_spec B), ρ ∈ c → ∀ (τ : allowable_spec B), τ ∈ c →
            ∀ (L : litter), flex L C →
            ((inr L.to_near_litter, C) ∈ (ρ : spec B).domain →
            (inr L.to_near_litter, C) ∈ (τ : spec B).domain) ∧
            ((inr L.to_near_litter, C) ∈ (ρ : spec B).range →
            (inr L.to_near_litter, C) ∈ (τ : spec B).range),
  { intros ρ hρ τ hτ L hL,
    split;
    refine λ Hρ, of_not_not (λ Hτ, _),
    specialize h τ hτ ρ hρ L hL (or.inl ⟨Hτ, Hρ⟩), swap,
    specialize h τ hτ ρ hρ L hL (or.inr ⟨Hτ, Hρ⟩),
    all_goals
    { refine h ((hc hτ hρ _).elim id $ λ h₁, _),
      { rintro rfl,
        exact h le_rfl },
      { simp only [mem_domain, spec.mem_range] at Hρ Hτ,
        simp only [←image_domain, ←image_range] at Hρ Hτ,
        obtain ⟨b, hb₁, hb₂⟩ := Hρ,
        rw ←hb₂ at Hτ,
        cases Hτ (mem_image_of_mem _ $ h₁.1 hb₁) } } },
  obtain ⟨hdom, hrge⟩ | ⟨hdom, hrge⟩ := hσ₁.flex_cond C,
  { refine spec.flex_cond.co_large _ _; sorry
    -- convert hdom using 3, swap, convert hrge using 3,
    -- all_goals
    -- { ext,
    --   rw [mem_set_of, mem_set_of, and.congr_right_iff],
    --   refine λ hx, ⟨λ hxc hxσ, hxc ⟨_, ⟨σ, Union_pos ⟨_, hσ₂, rfl⟩⟩, hxσ⟩, _⟩,
    --   rintro hxσ ⟨_, ⟨_, rfl⟩, ρ, ⟨⟨ρ, hρ₁, rfl⟩, rfl⟩, hρ₂⟩ },
    -- exact hxσ ((H ρ hρ₁ ⟨σ, hσ₁⟩ hσ₂ x hx).2 hρ₂),
    -- exact hxσ ((H ρ hρ₁ ⟨σ, hσ₁⟩ hσ₂ x hx).1 hρ₂)
    },
  { refine spec.flex_cond.all (λ L hL, _) (λ L hL, _);
      simp only [domain_supr, range_supr, mem_Union],
    { exact ⟨⟨σ, hσ₁⟩, hσ₂, hdom L hL⟩ },
    { exact ⟨⟨σ, hσ₁⟩, hσ₂, hrge L hL⟩ } }
end

lemma non_flex_cond_Union (hc : is_chain (≤) c) : (⨆ σ ∈ c, ↑σ : spec B).non_flex_cond B :=
begin
  rintro β γ δ hγ hδ hγδ N A t,
  simp_rw mem_supr,
  rintro ⟨σ, hσ₁, hσ₂⟩ π hπ,
  exact σ.prop.forward.non_flex_cond hγ hδ hγδ N A t hσ₂ π (hπ.mono $ lower_mono $ le_supr₂ σ hσ₁),
end

lemma domain_closed_Union (hc : is_chain (≤) c) : (⨆ σ ∈ c, ↑σ : spec B).domain.support_closed B :=
begin
  intros β γ δ hγ hδ hγδ A t h,
  simp_rw [spec.domain_supr, mem_Union] at h,
  simp_rw [spec.domain_supr, unary_spec.lower_Union],
  obtain ⟨σ, hσ₁, hσ₂⟩ := h,
  refine (σ.prop.forward.support_closed hγ hδ hγδ A t hσ₂).mono _,
  convert @subset_bUnion_of_mem (unary_spec B) _ (spec.domain ∘ subtype.val '' c)
    (λ i, i.lower $ A.cons hγ) (spec.domain σ) _ using 1,
  { simp only [mem_image, function.comp_app, subtype.val_eq_coe, subtype.exists, subtype.coe_mk,
      exists_and_distrib_right, Union_exists, bUnion_and', Union_Union_eq_right, Union_subtype] },
  { exact ⟨σ, hσ₁, rfl⟩ }
end

variables (hc : is_chain (≤) c)

/-- The union of a chain of allowable partial permutations is allowable. -/
lemma allowable_Union : (⨆ σ ∈ c, ↑σ : spec B).allowable B :=
have c_inv_chain : is_chain (≤) (has_inv.inv '' c) := hc.image _ _ _ inv_mono,
{ forward :=
  { one_to_one := one_to_one_Union hc,
    atom_cond := atom_cond_Union hc,
    near_litter_cond := near_litter_cond_Union hc,
    non_flex_cond := non_flex_cond_Union hc,
    support_closed := domain_closed_Union hc },
  backward :=
  { one_to_one := by sorry { exact one_to_one_Union c_inv_chain },
    atom_cond := by sorry { exact atom_cond_Union c_inv_chain },
    near_litter_cond := by sorry { exact near_litter_cond_Union c_inv_chain },
    non_flex_cond := by sorry {  exact non_flex_cond_Union c_inv_chain },
    support_closed := by sorry { exact domain_closed_Union c_inv_chain } },
  flex_cond := flex_cond_Union hc }

lemma le_Union₂ (σ τ : allowable_spec B) (hτ : τ ∈ c) : τ ≤ ⟨⨆ σ ∈ c, ↑σ, allowable_Union hc⟩ :=
begin
  have hsub : ∀ (t : allowable_spec B) (ht : t ∈ c), (t : spec B) ≤ ⨆ σ ∈ c, ↑σ,
  { intros t ht b hb,
    simp_rw mem_supr,
    exact ⟨t, ht, hb⟩ },
  refine ⟨hsub τ hτ,
    λ L N A hLA hnin hin l hla, _,
    λ L N A hLA hnin hin l hla, _,
    λ a b L h A hnin hin p hp, _,
    λ a b L h A hnin hin p hp, _⟩,
  all_goals
  { rw subtype.coe_mk at ⊢ hin,
    simp only [mem_supr, exists_prop, subtype.coe_mk] at hin,
    simp_rw [domain_supr, range_supr, mem_Union] <|> skip,
    simp only [domain_supr, mem_Union, mem_domain, exists_prop, subtype.coe_mk, range_supr,
      spec.mem_range] <|> skip,
    obtain ⟨ρ, hρc, hLρ⟩ := hin,
    have hneq : ρ ≠ τ,
    { rintro rfl,
      exact hnin hLρ },
    obtain ⟨hsub, -, -, -⟩ | hleq := hc hρc hτ hneq,
    { cases hnin (hsub hLρ) } },
  { have := hleq.2 L N A hLA hnin hLρ l hla,
    simp only [mem_domain, spec.mem_range] at this,
    exact ⟨⟨ρ, hρc, this.1⟩, ρ, hρc, this.2⟩ },
  { have := hleq.3 L N A hLA hnin hLρ l hla,
    simp only [mem_domain, spec.mem_range] at this,
    exact ⟨⟨ρ, hρc, this.1⟩, ρ, hρc, this.2⟩ },
  { obtain ⟨q, hq⟩ := hleq.4 a b L h A hnin hLρ p hp,
    exact ⟨q, (hsub ρ hρc) hq⟩ },
  { obtain ⟨q, hq⟩ := hleq.5 a b L h A hnin hLρ p hp,
    exact ⟨q, (hsub ρ hρc) hq⟩ }
end

lemma le_Union₁ (hcne : c.nonempty) (σ : allowable_spec B) (hc₁ : c ⊆ Ici σ) :
  σ ≤ ⟨⨆ σ ∈ c, ↑σ, allowable_Union hc⟩ :=
let ⟨τ, h⟩ := hcne in le_trans (hc₁ h) (le_Union₂ hc σ τ h)

end zorn_setup

/-- There is a maximal allowable partial permutation extending any given allowable partial
permutation. This result is due to Zorn's lemma. -/
lemma maximal_perm (σ : allowable_spec B) : ∃ m (H : σ ≤ m), σ ≤ m ∧ ∀ z, σ ≤ z → m ≤ z → z ≤ m :=
zorn_nonempty_preorder₀ {ρ | σ ≤ ρ}
  (λ c hc₁ hc₂ τ hτ,
    ⟨⟨⨆ σ ∈ c, ↑σ, allowable_Union hc₂⟩,
      le_Union₁ hc₂ ⟨τ, hτ⟩ σ hc₁,
      λ τ, le_Union₂ hc₂ σ τ⟩)
  σ (le_refl σ)

end allowable_spec
end con_nf
