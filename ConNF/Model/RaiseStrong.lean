import ConNF.Model.FOA

open Quiver Sum WithBot

open scoped Cardinal Pointwise symmDiff

universe u

noncomputable section

namespace ConNF.Support

variable [Params.{u}] [Level] {β γ : Λ} [iβ : LtLevel β] [iγ : LtLevel γ] (hγ : (γ : TypeIndex) < β)

local instance : FOAAssumptions := Construction.FOA.foaAssumptions

theorem toPath_comp_eq_cons {α β γ δ : TypeIndex} (hβ : β < α) (hγ : γ < α) (hδ : δ < γ)
    (A : Path β δ) (B : Path α γ)
    (h : (Hom.toPath hβ).comp A = B.cons hδ) :
    ∃ C : Path β γ, B = (Hom.toPath hβ).comp C := by
  induction' A with ε ζ A hε ih
  case nil =>
    cases h
    cases hγ.not_le le_rfl
  case cons =>
    simp only [Path.comp_cons, Path.cons.injEq] at h
    cases h.1
    simp only [heq_eq_eq, and_true, true_and] at h
    exact ⟨_, h.symm⟩

theorem raise_eq_cons_cons {α β γ δ : Λ} (hβ : (β : TypeIndex) < α) (hδ : (δ : TypeIndex) < γ)
    (c : Address β) (B : Path (α : TypeIndex) γ) (x : Atom ⊕ NearLitter)
    (h : raise hβ c = ⟨(B.cons hδ).cons (bot_lt_coe _), x⟩) :
    γ = α ∨ (∃ C : Path (β : TypeIndex) γ, B = (Hom.toPath hβ).comp C) := by
  by_cases hγ : (γ : TypeIndex) < α
  · simp only [raise, raiseIndex, Address.mk.injEq] at h
    obtain ⟨C, hC⟩ := toPath_comp_eq_cons hβ (hδ.trans hγ) (bot_lt_coe _) c.1 (B.cons hδ) h.1
    exact Or.inr (toPath_comp_eq_cons hβ hγ hδ C B hC.symm)
  · exact Or.inl (coe_injective (le_antisymm (le_of_path B) (le_of_not_lt hγ)))

theorem eq_raiseIndex_of_zero_lt_length {β : Λ} {δ : TypeIndex}
    {A : Path (β : TypeIndex) δ} (h : 0 < A.length) :
    ∃ (γ : TypeIndex) (hγ : γ < β) (B : Path (γ : TypeIndex) δ),
    A = (Hom.toPath hγ).comp B := by
  induction' A with ε ζ A hε ih
  · cases h
  · cases' A with η _ A hη
    · exact ⟨ζ, hε, Path.nil, rfl⟩
    · obtain ⟨γ, hγ, B, hB⟩ := ih (Nat.zero_lt_succ _)
      refine ⟨γ, hγ, B.cons hε, ?_⟩
      rw [hB]
      rfl

theorem eq_raiseIndex_of_one_lt_length {β : Λ} {A : ExtendedIndex β} (h : 1 < A.length) :
    ∃ (γ : Λ) (hγ : (γ : TypeIndex) < β) (B : ExtendedIndex γ),
    A = (Hom.toPath hγ).comp B := by
  obtain ⟨γ, hγ, B, hB⟩ := eq_raiseIndex_of_zero_lt_length (zero_lt_one.trans h)
  induction γ using recBotCoe
  · cases path_eq_nil B
    cases hB
    cases (lt_self_iff_false _).mp h
  · exact ⟨_, hγ, B, hB⟩

theorem eq_raise_of_one_lt_length {c : Address β} (h : 1 < c.path.length) :
    ∃ (γ : Λ) (hγ : (γ : TypeIndex) < β) (d : Address γ), c = raise hγ d := by
  obtain ⟨γ, hγ, B, hB⟩ := eq_raiseIndex_of_one_lt_length h
  exact ⟨γ, hγ, ⟨B, c.value⟩, Address.ext _ _ hB rfl⟩

theorem zero_lt_length (A : ExtendedIndex γ) : 0 < A.length := by
  by_contra h
  simp only [not_lt, nonpos_iff_eq_zero] at h
  cases Path.eq_of_length_zero _ h

theorem precedes_raise {c : Address β} {d : Address γ} (h : Precedes c (raise hγ d)) :
    1 < c.path.length ∨ ∃ a, c = ⟨Hom.toPath (bot_lt_coe _), inl a⟩ := by
  rw [precedes_iff] at h
  obtain (⟨A, N, h, e, -, hc, -⟩ | ⟨A, N, h, hc, hd⟩) := h
  · rw [hc]
    refine Or.inl ?_
    simp only [Path.length_comp, Path.length_cons]
    have := zero_lt_length e.path
    linarith
  · obtain (h' | ⟨C, hC⟩) := raise_eq_cons_cons _ _ _ _ _ hd
    · obtain ⟨⟨γ, ε, hε, B, hB⟩, a, hL⟩ := h
      dsimp only at h'
      cases h'
      cases path_eq_nil B
      rw [hc]
      exact Or.inr ⟨_, rfl⟩
    · rw [hc, hC]
      refine Or.inl ?_
      simp only [Path.length_cons, Path.length_comp, lt_add_iff_pos_left, add_pos_iff]
      exact Or.inl zero_lt_one

@[simp]
theorem raiseIndex_length (A : ExtendedIndex γ) :
    (raiseIndex hγ A).length = A.length + 1 := by
  rw [raiseIndex, Path.length_comp]
  exact add_comm _ _

theorem precClosure_raise_spec (T : Support γ) (c : Address β)
    (h : c ∈ precClosure (T.image (raise hγ))) :
    1 < c.path.length ∨ ∃ a, c = ⟨Hom.toPath (bot_lt_coe _), inl a⟩ := by
  obtain ⟨d, hd, hc⟩ := h
  induction' hc using Relation.ReflTransGen.head_induction_on with c' d' hcc' hcd' ih
  case refl =>
    simp only [Enumeration.image_carrier, Set.mem_image] at hd
    obtain ⟨d, _, rfl⟩ := hd
    refine Or.inl ?_
    simp only [raise_path, raiseIndex_length, lt_add_iff_pos_left]
    exact zero_lt_length d.path
  case head =>
    obtain (ih | ⟨a, rfl⟩) := ih
    · obtain ⟨δ, hδ, d, rfl⟩ := eq_raise_of_one_lt_length ih
      exact precedes_raise _ hcc'
    · simp only [not_precedes_atom] at hcc'

theorem strongSupport_raise_spec (T : Support γ) (c : Address β)
    (h : c ∈ strongSupport (T.image (raise hγ)).small) :
    1 < c.path.length ∨ ∃ a : Atom, c = ⟨Hom.toPath (bot_lt_coe _), inl a⟩ := by
  obtain ⟨i, hi, hc⟩ := h
  have := mem_of_strongSupport_f_eq (T.image (raise hγ)).small hi
  rw [← hc] at this
  obtain (⟨A, a, N₁, N₂, hN₁, _, _, rfl⟩ | h) := this
  · obtain (h | h) := precClosure_raise_spec hγ T _ hN₁
    · exact Or.inl h
    · simp only [Address.mk.injEq, and_false, exists_const] at h
  · exact precClosure_raise_spec hγ T c h

theorem path_eq_nil' {α β : TypeIndex} (h : α = β) (p : Quiver.Path α β) : Path.length p = 0 := by
  cases h
  cases path_eq_nil p
  rfl

theorem raise_smul_raise_strong (T : Support γ) (ρ : Allowable β) :
    Support.Strong ((ρ • strongSupport (T.image (raise hγ)).small).image (raise iβ.elim)) := by
  constructor
  · intro i₁ i₂ hi₁ hi₂ A N₁ N₂ hN₁ hN₂ a ha
    rw [Enumeration.image_f] at hN₁ hN₂
    have := (strongSupport_strong (T.image (raise hγ)).small).interferes hi₁ hi₂
        (A := ((strongSupport (T.image (raise hγ)).small).f i₁ hi₁).path) ?_ ?_
        (ha.smul (Allowable.toStructPerm ρ⁻¹
          ((strongSupport (T.image (raise hγ)).small).f i₁ hi₁).path))
    · obtain ⟨j, hj, hji₁, hji₂, hj'⟩ := this
      refine ⟨j, hj, hji₁, hji₂, ?_⟩
      rw [Enumeration.image_f, Enumeration.smul_f, hj']
      refine Address.ext _ _ ?_ ?_
      · have := congr_arg Address.path hN₁
        exact this
      · simp only [map_inv, Tree.inv_apply, Allowable.smul_address,
          smul_inl, smul_inv_smul, raise_value]
    · refine Address.ext _ _ rfl ?_
      have := congr_arg Address.value hN₁
      rw [Enumeration.smul_f, Allowable.smul_address, raise_value, smul_eq_iff_eq_inv_smul] at this
      simp only [this, smul_inr, map_inv, Tree.inv_apply]
    · refine Address.ext _ _ ?_ ?_
      · have h₁ := congr_arg Address.path hN₁
        have h₂ := congr_arg Address.path hN₂
        exact raiseIndex_injective _ (h₂.trans h₁.symm)
      · have := congr_arg Address.value hN₂
        rw [Enumeration.smul_f, Allowable.smul_address, raise_value,
          smul_eq_iff_eq_inv_smul] at this
        simp only [this, smul_inr, map_inv, Tree.inv_apply]
        have h₁ := congr_arg Address.path hN₁
        have h₂ := congr_arg Address.path hN₂
        have := raiseIndex_injective _ (h₂.trans h₁.symm)
        simp only [Enumeration.smul_f, Allowable.smul_address] at this
        rw [this]
  · intro i hi c hc
    rw [precedes_iff] at hc
    obtain (⟨A, N, h, d, hd, rfl, hc⟩ | ⟨A, N, h, rfl, hc⟩) := hc
    · obtain (hc' | ⟨a, ha⟩) := strongSupport_raise_spec hγ T _ ⟨i, hi, rfl⟩
      · obtain (hc'' | ⟨C, hC⟩) := raise_eq_cons_cons _ _ _ _ _ hc
        · have := congr_arg Path.length (congr_arg Address.path hc)
          rw [Path.length_cons, Path.length_cons, Enumeration.image_f, raise_path,
            raiseIndex_length, path_eq_nil' (coe_inj.mpr hc''.symm) h.path.B, add_left_inj,
            Enumeration.smul_f, Allowable.smul_address] at this
          rw [this, lt_self_iff_false] at hc'
          cases hc'
        · obtain ⟨⟨γ, δ, ε, hδ, hε, hδε, A, rfl⟩, t, hL⟩ := h
          rw [hC, Enumeration.image_f, ← Path.comp_cons, ← Path.comp_cons] at hc
          change raise iβ.elim _ = raise iβ.elim ⟨(C.cons hε).cons (bot_lt_coe _), inr N⟩ at hc
          have := (strongSupport_strong (T.image (raise hγ)).small).precedes hi
            (ρ⁻¹ • ⟨(C.cons hδ).comp d.path, d.value⟩) ?_
          · obtain ⟨j, hj₁, hj₂, hj₃⟩ := this
            refine ⟨j, hj₁, hj₂, ?_⟩
            rw [Enumeration.image_f, Enumeration.smul_f, hj₃, hC, raise, Hom.toPath, raiseIndex,
              ← Path.comp_cons, Path.comp_assoc, smul_inv_smul]
            rfl
          · have := raise_injective _ hc
            rw [Enumeration.smul_f, smul_eq_iff_eq_inv_smul] at this
            rw [this]
            exact (Precedes.fuzz ((C.cons hε).cons (bot_lt_coe _)) N
              ⟨⟨γ, δ, ε, hδ, hε, hδε, _, rfl⟩, t, hL⟩ d hd).smul ρ⁻¹
      · have h₁ := congr_arg Address.value hc
        rw [Enumeration.image_f, Enumeration.smul_f, raise_value, Allowable.smul_address,
          smul_eq_iff_eq_inv_smul] at h₁
        have h₂ := congr_arg Address.value ha
        cases h₁.symm.trans h₂
    · obtain (hc' | ⟨a, ha⟩) := strongSupport_raise_spec hγ T _ ⟨i, hi, rfl⟩
      · obtain (hc'' | ⟨C, hC⟩) := raise_eq_cons_cons _ _ _ _ _ hc
        · have := congr_arg Path.length (congr_arg Address.path hc)
          rw [Path.length_cons, Path.length_cons, Enumeration.image_f, raise_path,
            raiseIndex_length, path_eq_nil' (coe_inj.mpr hc''.symm) h.path.B, add_left_inj,
            Enumeration.smul_f, Allowable.smul_address] at this
          rw [this, lt_self_iff_false] at hc'
          cases hc'
        · obtain ⟨⟨γ, ε, hε, A, rfl⟩, a, hL⟩ := h
          rw [hC, Enumeration.image_f, ← Path.comp_cons, ← Path.comp_cons] at hc
          change raise iβ.elim _ = raise iβ.elim ⟨(C.cons hε).cons (bot_lt_coe _), inr N⟩ at hc
          have := (strongSupport_strong (T.image (raise hγ)).small).precedes hi
            (ρ⁻¹ • ⟨C.cons (bot_lt_coe _), inl a⟩) ?_
          · obtain ⟨j, hj₁, hj₂, hj₃⟩ := this
            refine ⟨j, hj₁, hj₂, ?_⟩
            rw [Enumeration.image_f, Enumeration.smul_f, hj₃, hC, smul_inv_smul]
            rfl
          · have := raise_injective _ hc
            rw [Enumeration.smul_f, smul_eq_iff_eq_inv_smul] at this
            rw [this]
            exact (Precedes.fuzzBot ((C.cons hε).cons (bot_lt_coe _)) N
              ⟨⟨γ, ε, hε, _, rfl⟩, a, hL⟩).smul ρ⁻¹
      · have h₁ := congr_arg Address.value hc
        rw [Enumeration.image_f, Enumeration.smul_f, raise_value, Allowable.smul_address,
          smul_eq_iff_eq_inv_smul] at h₁
        have h₂ := congr_arg Address.value ha
        cases h₁.symm.trans h₂

def interference (S : Support α) (T : Support γ) : Set (Address β) :=
  {c | ∃ A : ExtendedIndex β, ∃ a : Atom, ∃ N₁ N₂ : NearLitter, c = ⟨A, inl a⟩ ∧
    raise iβ.elim ⟨A, inr N₁⟩ ∈ S ∧ ⟨A, inr N₂⟩ ∈ strongSupport (T.image (raise hγ)).small ∧
    Interferes a N₁ N₂}

def interference' (S : Support α) (T : Support γ) : Set (Address β) :=
  ⋃ (A : ExtendedIndex β) (N₁ ∈ {N | raise iβ.elim ⟨A, inr N⟩ ∈ S})
    (N₂ ∈ {N | ⟨A, inr N⟩ ∈ strongSupport (T.image (raise hγ)).small})
    (a ∈ {a | Interferes a N₁ N₂}),
    {⟨A, inl a⟩}

theorem interference_eq_interference' (S : Support α) (T : Support γ) :
    interference hγ S T = interference' hγ S T := by
  rw [interference, interference']
  aesop

theorem interference_small {S : Support α} {T : Support γ} : Small (interference hγ S T) := by
  rw [interference_eq_interference']
  refine small_iUnion ?_ (fun A => ?_)
  · exact (mk_extendedIndex β).trans_lt Params.Λ_lt_κ
  refine Small.bUnion ?_ (fun N₁ _ => ?_)
  · refine S.small.preimage ?_
    intro N₁ N₂ h
    cases h
    rfl
  refine Small.bUnion ?_ (fun N₂ _ => ?_)
  · refine (strongSupport (T.image (raise hγ)).small).small.preimage ?_
    intro N₁ N₂ h
    cases h
    rfl
  refine Small.bUnion (interferes_small _ _) (fun a _ => ?_)
  exact small_singleton _

def interferenceSupport (S : Support α) (T : Support γ) : Support β :=
  Enumeration.ofSet (interference hγ S T) (interference_small hγ)

theorem mem_interferenceSupport_iff (S : Support α) (T : Support γ) (c : Address β) :
    c ∈ interferenceSupport hγ S T ↔ c ∈ interference hγ S T :=
  Enumeration.mem_ofSet_iff _ _ _

theorem interferenceSupport_ne_nearLitter {S : Support α} {T : Support γ}
    {N : NearLitter} {i : κ} (hi : i < (interferenceSupport hγ S T).max) :
    ((interferenceSupport hγ S T).f i hi).value ≠ inr N := by
  intro h
  have := (mem_interferenceSupport_iff hγ S T ⟨_, inr N⟩).mp ⟨i, hi, Address.ext _ _ rfl h.symm⟩
  rw [interference] at this
  simp only [Enumeration.image_carrier, exists_and_left, Set.mem_setOf_eq, Address.mk.injEq,
    and_false, false_and, exists_const] at this

theorem interferenceSupport_eq_atom {S : Support α} {T : Support γ}
    {i : κ} (hi : i < (interferenceSupport hγ S T).max) :
    ∃ A a, (interferenceSupport hγ S T).f i hi = ⟨A, inl a⟩ := by
  set c := (interferenceSupport hγ S T).f i hi with hc
  obtain ⟨A, a | N⟩ := c
  · exact ⟨A, a, rfl⟩
  · have := interferenceSupport_ne_nearLitter hγ hi (N := N)
    rw [← hc] at this
    cases this rfl

def raiseRaise (S : Support α) (T : Support γ) (ρ : Allowable β) : Support α :=
    ((ρ • interferenceSupport hγ S T).image (raise iβ.elim)) +
      S + ((ρ • strongSupport (T.image (raise hγ)).small).image (raise iβ.elim))

variable {hγ} {S : Support α} {T : Support γ} {ρ ρ₁ ρ₂ : Allowable β}

theorem raiseRaise_max : (raiseRaise hγ S T ρ).max =
    (interferenceSupport hγ S T).max + S.max + (strongSupport (T.image (raise hγ)).small).max :=
  rfl

theorem raiseRaise_f_eq₁ {i : κ} (hi : i < (interferenceSupport hγ S T).max) :
    (raiseRaise hγ S T ρ).f i ((hi.trans_le (κ_le_self_add _ _)).trans_le (κ_le_self_add _ _)) =
    raise iβ.elim (ρ • (interferenceSupport hγ S T).f i hi) := by
  unfold raiseRaise
  rw [Enumeration.add_f_left (by exact hi.trans_le (κ_le_self_add _ _)),
    Enumeration.add_f_left (by exact hi)]
  rfl

theorem raiseRaise_f_eq₂ {i : κ} (hi₁ : (interferenceSupport hγ S T).max ≤ i)
    (hi₂ : i < (interferenceSupport hγ S T).max + S.max) :
    (raiseRaise hγ S T ρ).f i (hi₂.trans_le (κ_le_self_add _ _)) =
    S.f (i - (interferenceSupport hγ S T).max) (κ_sub_lt hi₂ hi₁) := by
  unfold raiseRaise
  rw [Enumeration.add_f_left (by exact hi₂), Enumeration.add_f_right (by exact hi₂) (by exact hi₁)]
  rfl

theorem raiseRaise_f_eq₃ {i : κ} (hi₁ : (interferenceSupport hγ S T).max + S.max ≤ i)
    (hi₂ : i < (raiseRaise hγ S T ρ).max) :
    (raiseRaise hγ S T ρ).f i hi₂ =
    raise iβ.elim (ρ • (strongSupport (T.image (raise hγ)).small).f
      (i - ((interferenceSupport hγ S T).max + S.max)) (κ_sub_lt hi₂ hi₁)) := by
  unfold raiseRaise
  rw [Enumeration.add_f_right (by exact hi₂) (by exact hi₁)]
  rfl

theorem raiseRaise_cases {i : κ} (hi : i < (raiseRaise hγ S T ρ).max) :
    (i < (interferenceSupport hγ S T).max) ∨
    ((interferenceSupport hγ S T).max ≤ i ∧ i < (interferenceSupport hγ S T).max + S.max) ∨
    ((interferenceSupport hγ S T).max + S.max ≤ i ∧ i < (raiseRaise hγ S T ρ).max) := by
  by_cases h₁ : i < (interferenceSupport hγ S T).max
  · exact Or.inl h₁
  by_cases h₂ : i < (interferenceSupport hγ S T).max + S.max
  · exact Or.inr (Or.inl ⟨le_of_not_lt h₁, h₂⟩)
  · exact Or.inr (Or.inr ⟨le_of_not_lt h₂, hi⟩)

variable (hS : S.Strong)

theorem raiseIndex_of_raise_eq {c : Address β} {d : Address α} (h : raise iβ.elim c = d) :
    ∃ A, raiseIndex iβ.elim A = d.path :=
  ⟨c.path, congr_arg Address.path h⟩

theorem raise_injective' {c : Address γ} {A : ExtendedIndex γ} {x : Atom ⊕ NearLitter}
    (h : raise hγ c = ⟨raiseIndex hγ A, x⟩) : c = ⟨A, x⟩ := by
  refine Address.ext _ _ ?_ ?_
  · exact raiseIndex_injective hγ (congr_arg Address.path h)
  · have := congr_arg Address.value h
    exact this

theorem raiseRaise_strong (hρS : ∀ c : Address β, raise iβ.elim c ∈ S → ρ • c = c) :
    (raiseRaise hγ S T ρ).Strong := by
  constructor
  · intro i₁ i₂ hi₁ hi₂ A N₁ N₂ hN₁ hN₂ a ha
    obtain (hi₁ | ⟨hi₁, hi₁'⟩ | ⟨hi₁, hi₁'⟩) := raiseRaise_cases hi₁
    · rw [raiseRaise_f_eq₁ hi₁] at hN₁
      simp only [Allowable.smul_address, raise, Address.mk.injEq, smul_eq_iff_eq_inv_smul] at hN₁
      cases interferenceSupport_ne_nearLitter hγ hi₁ hN₁.2
    · rw [raiseRaise_f_eq₂ hi₁ hi₁'] at hN₁
      obtain (hi₂ | ⟨hi₂, hi₂'⟩ | ⟨hi₂, hi₂'⟩) := raiseRaise_cases hi₂
      · rw [raiseRaise_f_eq₁ hi₂] at hN₂
        simp only [Allowable.smul_address, raise, Address.mk.injEq, smul_eq_iff_eq_inv_smul] at hN₂
        cases interferenceSupport_ne_nearLitter hγ hi₂ hN₂.2
      · rw [raiseRaise_f_eq₂ hi₂ hi₂'] at hN₂
        obtain ⟨j, hj, hj₁, hj₂, hj'⟩ := hS.interferes _ _ hN₁ hN₂ ha
        refine ⟨(interferenceSupport hγ S T).max + j, ?_, ?_, ?_, ?_⟩
        · rw [raiseRaise_max, add_assoc]
          refine add_lt_add_left ?_ _
          exact hj.trans_le (κ_le_self_add _ _)
        · rwa [← κ_lt_sub_iff]
        · rwa [← κ_lt_sub_iff]
        · rw [raiseRaise_f_eq₂]
          · simp_rw [κ_add_sub_cancel]
            exact hj'
          · rw [le_add_iff_nonneg_right]
            exact κ_pos _
          · rwa [add_lt_add_iff_left]
      · rw [raiseRaise_f_eq₃ hi₂ hi₂'] at hN₂
        obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq hN₂
        have := raise_injective' hN₂
        rw [smul_eq_iff_eq_inv_smul] at this
        have := (mem_interferenceSupport_iff hγ S T ⟨A, inl (Allowable.toStructPerm ρ⁻¹ A • a)⟩).mpr
          ⟨A, _, N₁, _, rfl, ⟨_, _, hN₁.symm⟩, ⟨_, _, this.symm⟩, ?_⟩
        · obtain ⟨j, hj, hj'⟩ := this
          refine ⟨j, ?_, ?_, ?_, ?_⟩
          · rw [raiseRaise_max, add_assoc]
            exact hj.trans_le (κ_le_self_add _ _)
          · exact hj.trans_le hi₁
          · exact hj.trans_le ((κ_le_self_add _ _).trans hi₂)
          · rw [raiseRaise_f_eq₁ hj, ← hj', Allowable.smul_address]
            simp only [map_inv, Tree.inv_apply, smul_inl, smul_inv_smul]
            rfl
        · convert ha.smul (Allowable.toStructPerm ρ⁻¹ A) using 1
          have := hρS ⟨A, inr N₁⟩ ⟨_, _, hN₁.symm⟩
          simp only [Allowable.smul_address, smul_inr, Address.mk.injEq, inr.injEq, true_and]
            at this
          rw [map_inv, Tree.inv_apply, eq_inv_smul_iff, this]
    · rw [raiseRaise_f_eq₃ hi₁ hi₁'] at hN₁
      obtain (hi₂ | ⟨hi₂, hi₂'⟩ | ⟨hi₂, hi₂'⟩) := raiseRaise_cases hi₂
      · rw [raiseRaise_f_eq₁ hi₂] at hN₂
        simp only [Allowable.smul_address, raise, Address.mk.injEq, smul_eq_iff_eq_inv_smul] at hN₂
        cases interferenceSupport_ne_nearLitter hγ hi₂ hN₂.2
      · rw [raiseRaise_f_eq₂ hi₂ hi₂'] at hN₂
        obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq hN₁
        have := raise_injective' hN₁
        rw [smul_eq_iff_eq_inv_smul] at this
        have := (mem_interferenceSupport_iff hγ S T ⟨A, inl (Allowable.toStructPerm ρ⁻¹ A • a)⟩).mpr
          ⟨A, _, _, _, rfl, ⟨_, _, hN₂.symm⟩, ⟨_, _, this.symm⟩, ?_⟩
        · obtain ⟨j, hj, hj'⟩ := this
          refine ⟨j, ?_, ?_, ?_, ?_⟩
          · rw [raiseRaise_max, add_assoc]
            exact hj.trans_le (κ_le_self_add _ _)
          · exact hj.trans_le ((κ_le_self_add _ _).trans hi₁)
          · exact hj.trans_le hi₂
          · rw [raiseRaise_f_eq₁ hj, ← hj', Allowable.smul_address]
            simp only [map_inv, Tree.inv_apply, smul_inl, smul_inv_smul]
            rfl
        · convert ha.symm.smul (Allowable.toStructPerm ρ⁻¹ A) using 1
          have := hρS ⟨A, inr N₂⟩ ⟨_, _, hN₂.symm⟩
          simp only [Allowable.smul_address, smul_inr, Address.mk.injEq, inr.injEq, true_and]
            at this
          rw [map_inv, Tree.inv_apply, eq_inv_smul_iff, this]
      · rw [raiseRaise_f_eq₃ hi₂ hi₂'] at hN₂
        obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq hN₂
        have hN₁' := raise_injective' hN₁
        have hN₂' := raise_injective' hN₂
        rw [smul_eq_iff_eq_inv_smul] at hN₁' hN₂'
        obtain ⟨j, hj, hj₁, hj₂, hj'⟩ :=
          (strongSupport_strong (T.image (raise hγ)).small).interferes _ _ hN₁' hN₂' (ha.smul _)
        refine ⟨(interferenceSupport hγ S T).max + S.max + j, ?_, ?_, ?_, ?_⟩
        · rw [raiseRaise_max]
          exact add_lt_add_left hj _
        · rw [κ_lt_sub_iff] at hj₁
          refine lt_of_le_of_lt ?_ hj₁
          rw [add_assoc, add_le_add_iff_left]
        · rw [κ_lt_sub_iff] at hj₂
          refine lt_of_le_of_lt ?_ hj₂
          rw [add_assoc, add_le_add_iff_left]
        · rw [raiseRaise_f_eq₃]
          · simp_rw [κ_add_sub_cancel]
            rw [hj']
            simp only [map_inv, Tree.inv_apply, Allowable.smul_address, smul_inl, smul_inv_smul]
            rfl
          · rw [le_add_iff_nonneg_right]
            exact κ_pos _
  · intro i hi c hc
    obtain (hi | ⟨hi, hi'⟩ | ⟨hi, hi'⟩) := raiseRaise_cases hi
    · rw [raiseRaise_f_eq₁ hi] at hc
      obtain ⟨A, a, ha⟩ := interferenceSupport_eq_atom hγ hi
      rw [ha] at hc
      cases not_precedes_atom hc
    · rw [raiseRaise_f_eq₂ hi hi'] at hc
      obtain ⟨j, hj₁, hj₂, hj₃⟩ := hS.precedes _ _ hc
      refine ⟨(interferenceSupport hγ S T).max + j, ?_, ?_, ?_⟩
      · rw [raiseRaise_max, add_assoc, add_lt_add_iff_left]
        exact hj₁.trans_le (κ_le_self_add _ _)
      · rwa [κ_lt_sub_iff] at hj₂
      · rw [raiseRaise_f_eq₂]
        · simp_rw [κ_add_sub_cancel]
          exact hj₃
        · exact κ_le_self_add _ _
        · rwa [add_lt_add_iff_left]
    · rw [raiseRaise_f_eq₃ hi hi'] at hc
      obtain ⟨j, hj₁, hj₂, hj₃⟩ := (raise_smul_raise_strong hγ T ρ).precedes _ _ hc
      refine ⟨(interferenceSupport hγ S T).max + S.max + j, ?_, ?_, ?_⟩
      · rwa [raiseRaise_max, add_lt_add_iff_left]
      · rwa [κ_lt_sub_iff] at hj₂
      · rw [raiseRaise_f_eq₃]
        · simp_rw [κ_add_sub_cancel]
          exact hj₃
        · exact κ_le_self_add _ _

theorem raiseRaise_max_eq_max : (raiseRaise hγ S T 1).max = (raiseRaise hγ S T ρ).max := rfl

theorem raiseRaise_ne_nearLitter
    {i : κ} (hi : i < (interferenceSupport hγ S T).max) {A : ExtendedIndex α} {N : NearLitter} :
    (raiseRaise hγ S T ρ).f i ((hi.trans_le (κ_le_self_add _ _)).trans_le (κ_le_self_add _ _)) ≠
      ⟨A, inr N⟩ := by
  intro h
  rw [raiseRaise_f_eq₁ hi, raise, Allowable.smul_address, Address.mk.injEq,
    smul_eq_iff_eq_inv_smul, smul_inr] at h
  exact interferenceSupport_ne_nearLitter hγ hi h.2

theorem raiseRaise_f_eq_atom (i : κ) (hi : i < (raiseRaise hγ S T ρ₁).max)
    (A : ExtendedIndex α) (a : Atom) (ha : (raiseRaise hγ S T ρ₁).f i hi = ⟨A, inl a⟩) :
    ∃ b, (raiseRaise hγ S T ρ₂).f i hi = ⟨A, inl b⟩ := by
  obtain (hi | ⟨hi, hi'⟩ | ⟨hi, hi'⟩) := raiseRaise_cases hi
  · rw [raiseRaise_f_eq₁ hi] at ha ⊢
    simp only [Allowable.smul_address, raise, Address.mk.injEq, smul_eq_iff_eq_inv_smul, smul_inl,
      one_smul] at ha ⊢
    refine ⟨Allowable.toStructPerm (ρ₂ * ρ₁⁻¹) ((interferenceSupport hγ S T).f i hi).path • a,
      ha.1, ?_⟩
    simp only [ha.2, map_mul, map_inv, Tree.mul_apply, Tree.inv_apply, mul_smul, inv_smul_smul]
  · rw [raiseRaise_f_eq₂ hi hi'] at ha ⊢
    exact ⟨a, ha⟩
  · rw [raiseRaise_f_eq₃ hi hi'] at ha
    rw [raiseRaise_f_eq₃ hi (by exact hi')]
    simp only [Allowable.smul_address, raise, Address.mk.injEq, smul_eq_iff_eq_inv_smul, smul_inl,
      one_smul] at ha ⊢
    refine ⟨Allowable.toStructPerm (ρ₂ * ρ₁⁻¹) ((strongSupport (T.image (raise hγ)).small).f
        (i - ((interferenceSupport hγ S T).max + S.max)) ?_).path • a,
      ha.1, ?_⟩
    · rw [raiseRaise_max, ← κ_sub_lt_iff hi] at hi'
      exact hi'
    · simp only [ha.2, map_mul, map_inv, Tree.mul_apply, Tree.inv_apply, mul_smul, inv_smul_smul]

theorem raiseRaise_f_eq_nearLitter (i : κ) (hi : i < (raiseRaise hγ S T ρ₁).max)
    (A : ExtendedIndex α) (N : NearLitter) (hN : (raiseRaise hγ S T ρ₁).f i hi = ⟨A, inr N⟩) :
    ∃ N', (raiseRaise hγ S T ρ₂).f i hi = ⟨A, inr N'⟩ := by
  obtain (hi | ⟨hi, hi'⟩ | ⟨hi, hi'⟩) := raiseRaise_cases hi
  · cases raiseRaise_ne_nearLitter hi hN
  · rw [raiseRaise_f_eq₂ hi hi'] at hN ⊢
    exact ⟨N, hN⟩
  · rw [raiseRaise_f_eq₃ hi hi'] at hN
    rw [raiseRaise_f_eq₃ hi (by exact hi')]
    simp only [Allowable.smul_address, raise, Address.mk.injEq, smul_eq_iff_eq_inv_smul, smul_inr,
      one_smul] at hN ⊢
    refine ⟨Allowable.toStructPerm (ρ₂ * ρ₁⁻¹) ((strongSupport (T.image (raise hγ)).small).f
        (i - ((interferenceSupport hγ S T).max + S.max)) ?_).path • N,
      hN.1, ?_⟩
    · rw [raiseRaise_max, ← κ_sub_lt_iff hi] at hi'
      exact hi'
    · simp only [hN.2, map_mul, map_inv, Tree.mul_apply, Tree.inv_apply, mul_smul, inv_smul_smul]

theorem raiseRaise_cases_nearLitter {i : κ} {hi : i < (raiseRaise hγ S T ρ₁).max}
    {A : ExtendedIndex α} {N₁ N₂ : NearLitter}
    (h₁ : (raiseRaise hγ S T ρ₁).f i hi = ⟨A, inr N₁⟩)
    (h₂ : (raiseRaise hγ S T ρ₂).f i hi = ⟨A, inr N₂⟩) :
    ((interferenceSupport hγ S T).max ≤ i ∧ i < (interferenceSupport hγ S T).max + S.max) ∨
    ((interferenceSupport hγ S T).max + S.max ≤ i ∧ i < (raiseRaise hγ S T ρ₁).max ∧
      ∃ B : ExtendedIndex β, A = raiseIndex iβ.elim B) := by
  obtain (hi | hi | ⟨hi, hi'⟩) := raiseRaise_cases hi
  · cases raiseRaise_ne_nearLitter hi h₁
  · exact Or.inl hi
  · rw [raiseRaise_f_eq₃ hi (by exact hi')] at h₁ h₂
    have : 0 < A.length
    · have := congr_arg (Path.length ∘ Address.path) h₁
      simp only [Allowable.smul_address, Function.comp_apply,
        raise_path, raiseIndex_length, Path.length_cons, add_left_inj] at this
      linarith
    obtain ⟨β', hβ', A, rfl⟩ := eq_raiseIndex_of_zero_lt_length this
    obtain ⟨B, hB⟩ := raiseIndex_of_raise_eq h₁
    exact Or.inr ⟨hi, hi', B, hB.symm⟩

theorem raiseRaise_inflexibleCoe₃ {i : κ}
    (hi : (interferenceSupport hγ S T).max + S.max ≤ i) (hi' : i < (raiseRaise hγ S T ρ).max)
    {A : ExtendedIndex β} {N₁ N₂ : NearLitter}
    (h₁ : (raiseRaise hγ S T ρ₁).f i hi' = ⟨raiseIndex iβ.elim A, inr N₁⟩)
    (h₂ : (raiseRaise hγ S T ρ₂).f i hi' = ⟨raiseIndex iβ.elim A, inr N₂⟩)
    (h : InflexibleCoe (raiseIndex iβ.elim A) N₁.1) :
    ∃ (P : InflexibleCoePath A) (t : Tangle P.δ),
    N₁.1 = fuzz P.hδε (Allowable.comp (P.B.cons P.hδ) ρ₁ • t) ∧
    N₂.1 = fuzz P.hδε (Allowable.comp (P.B.cons P.hδ) ρ₂ • t) := by
  rw [raiseRaise_f_eq₃ hi (by exact hi')] at h₁ h₂
  obtain ⟨⟨γ, δ, ε, hδ, hε, hδε, B, hB⟩, t, hL⟩ := h
  have : 0 < B.length
  · have := strongSupport_raise_spec hγ T _
      ⟨i - ((interferenceSupport hγ S T).max + S.max), ?_, rfl⟩
    swap
    · rw [κ_sub_lt_iff hi]
      exact hi'
    obtain (h | ⟨a, ha⟩) := this
    · have h₁ := congr_arg (Path.length ∘ Address.path) h₁
      have h₂ := congr_arg Path.length hB
      simp only [Allowable.smul_address, Function.comp_apply, raise_path,
        raiseIndex_length, Path.length_cons, add_left_inj] at h₁ h₂
      linarith
    · have h₁ := congr_arg Address.value h₁
      have h₂ := congr_arg Address.value ha
      rw [Allowable.smul_address, raise_value, smul_eq_iff_eq_inv_smul] at h₁
      cases h₁.symm.trans h₂
  obtain ⟨β', hβ', B, rfl⟩ := eq_raiseIndex_of_zero_lt_length this
  rw [← Path.comp_cons, ← Path.comp_cons] at hB
  cases Path.comp_injective' (by rfl) hB
  cases raiseIndex_injective _ hB
  refine ⟨⟨γ, δ, ε, hδ, hε, hδε, B, rfl⟩, Allowable.comp (B.cons hδ) ρ₁⁻¹ • t, ?_, ?_⟩
  · simp only [hL, map_inv, smul_inv_smul]
  · rw [← toStructPerm_smul_fuzz hδ hε hδε, ← toStructPerm_smul_fuzz hδ hε hδε,
      ← hL, ← inv_smul_eq_iff]
    simp only [map_inv, Tree.inv_apply]
    have h₁' := congr_arg Address.value h₁
    have h₂' := congr_arg Address.value h₂
    simp only [raise_value, Allowable.smul_address, smul_eq_iff_eq_inv_smul] at h₁' h₂'
    have := h₁'.symm.trans h₂'
    simp only [smul_inr, inr.injEq] at this
    have := congr_arg Sigma.fst this
    simp only [NearLitterPerm.smul_nearLitter_fst] at this
    rw [← raiseIndex_injective _ (congr_arg Address.path h₁)]
    exact this.symm

theorem raiseRaise_eq_cases {i : κ} {hi : i < (raiseRaise hγ S T ρ).max} {c : Address α}
    (h : (raiseRaise hγ S T ρ).f i hi = c) :
    (∃ d, c = raise iβ.elim (ρ • d) ∧ (raiseRaise hγ S T 1).f i hi = raise iβ.elim d) ∨
    (c ∈ S ∧ (raiseRaise hγ S T 1).f i hi = c) := by
  obtain (hi | ⟨hi, hi'⟩ | ⟨hi, hi'⟩) := raiseRaise_cases hi
  · rw [raiseRaise_f_eq₁ hi] at h ⊢
    refine Or.inl ⟨_, h.symm, ?_⟩
    rw [one_smul]
  · refine Or.inr ?_
    rw [raiseRaise_f_eq₂ hi hi'] at h ⊢
    exact ⟨⟨_, _, h.symm⟩, h⟩
  · rw [raiseRaise_f_eq₃ hi (by exact hi')] at h ⊢
    refine Or.inl ⟨_, h.symm, ?_⟩
    rw [one_smul]

theorem raiseRaise_atom_spec₁_raise
    (hρ₁S : ∀ c : Address β, raise iβ.elim (ρ₁ • c) ∈ S → ρ₁ • c = ρ₂ • c)
    {A : ExtendedIndex α} {a₁ a₂ : Atom} {c : Address β}
    (ha₁ : raise iβ.elim (ρ₁ • c) = ⟨A, inl a₁⟩)
    (ha₂ : raise iβ.elim (ρ₂ • c) = ⟨A, inl a₂⟩) :
    {j | ∃ hj, (raiseRaise hγ S T ρ₁).f j hj = ⟨A, inl a₁⟩} ⊆
    {j | ∃ hj, (raiseRaise hγ S T ρ₂).f j hj = ⟨A, inl a₂⟩} := by
  obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq ha₁
  have ha₁ := raise_injective' ha₁
  have ha₂ := raise_injective' ha₂
  rintro j ⟨hj₁, hj₂⟩
  refine ⟨hj₁, ?_⟩
  change _ = raise iβ.elim ⟨A, inl _⟩ at hj₂ ⊢
  obtain (hj | ⟨hj, hj'⟩ | ⟨hj, hj'⟩) := raiseRaise_cases hj₁
  · rw [raiseRaise_f_eq₁ hj] at hj₂ ⊢
    have := raise_injective _ hj₂
    rw [smul_eq_iff_eq_inv_smul] at ha₂
    rw [← ha₁, ha₂, smul_left_cancel_iff, ← smul_eq_iff_eq_inv_smul] at this
    rw [this]
  · rw [raiseRaise_f_eq₂ hj hj'] at hj₂ ⊢
    rw [hj₂, ← ha₁, hρ₁S c ⟨_, _, ha₁.symm ▸ hj₂.symm⟩, ha₂]
  · rw [raiseRaise_f_eq₃ hj (by exact hj')] at hj₂ ⊢
    have := raise_injective _ hj₂
    rw [smul_eq_iff_eq_inv_smul] at ha₂
    rw [← ha₁, ha₂, smul_left_cancel_iff, ← smul_eq_iff_eq_inv_smul] at this
    rw [this]

theorem raiseRaise_atom_spec₁
    (hρ₁S : ∀ c : Address β, raise iβ.elim (ρ₁ • c) ∈ S → ρ₁ • c = ρ₂ • c)
    {i : κ} {hi : i < (raiseRaise hγ S T ρ₁).max}
    {A : ExtendedIndex α} {a₁ a₂ : Atom}
    (ha₁ : (raiseRaise hγ S T ρ₁).f i hi = ⟨A, inl a₁⟩)
    (ha₂ : (raiseRaise hγ S T ρ₂).f i hi = ⟨A, inl a₂⟩) :
    {j | ∃ hj, (raiseRaise hγ S T ρ₁).f j hj = ⟨A, inl a₁⟩} ⊆
    {j | ∃ hj, (raiseRaise hγ S T ρ₂).f j hj = ⟨A, inl a₂⟩} := by
  obtain (hi | ⟨hi, hi'⟩ | ⟨hi, hi'⟩) := raiseRaise_cases hi
  · rw [raiseRaise_f_eq₁ hi] at ha₁ ha₂
    exact raiseRaise_atom_spec₁_raise hρ₁S ha₁ ha₂
  · rw [raiseRaise_f_eq₂ hi hi'] at ha₁ ha₂
    have := ha₁.symm.trans ha₂
    simp only [Address.mk.injEq, inl.injEq, true_and] at this
    subst this
    rintro j ⟨hj₁, hj₂⟩
    refine ⟨hj₁, ?_⟩
    obtain (hj | ⟨hj, hj'⟩ | ⟨hj, hj'⟩) := raiseRaise_cases hj₁
    · rw [raiseRaise_f_eq₁ hj] at hj₂ ⊢
      obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq hj₂
      have hj₂ := raise_injective' hj₂
      rw [smul_eq_iff_eq_inv_smul] at hj₂
      rw [hj₂, ← hρ₁S (ρ₁⁻¹ • ⟨A, inl a₁⟩), smul_inv_smul]
      rfl
      rw [smul_inv_smul]
      exact ⟨_, _, ha₁.symm⟩
    · rw [raiseRaise_f_eq₂ hj hj'] at hj₂ ⊢
      exact hj₂
    · rw [raiseRaise_f_eq₃ hj (by exact hj')] at hj₂ ⊢
      obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq hj₂
      have hj₂ := raise_injective' hj₂
      rw [smul_eq_iff_eq_inv_smul] at hj₂
      rw [hj₂, ← hρ₁S (ρ₁⁻¹ • ⟨A, inl a₁⟩), smul_inv_smul]
      rfl
      rw [smul_inv_smul]
      exact ⟨_, _, ha₁.symm⟩
  · rw [raiseRaise_f_eq₃ hi (by exact hi')] at ha₁ ha₂
    exact raiseRaise_atom_spec₁_raise hρ₁S ha₁ ha₂

theorem raiseRaise_atom_spec₂_raise
    (hρS : ∀ c : Address β, raise iβ.elim c ∈ S → ρ₁⁻¹ • c = ρ₂⁻¹ • c)
    {A : ExtendedIndex α} {a₁ a₂ : Atom} {c : Address β}
    (ha₁ : raise iβ.elim (ρ₁ • c) = ⟨A, inl a₁⟩)
    (ha₂ : raise iβ.elim (ρ₂ • c) = ⟨A, inl a₂⟩) :
    {j | ∃ hj, ∃ N, (raiseRaise hγ S T ρ₁).f j hj = ⟨A, inr N⟩ ∧ a₁ ∈ N} ⊆
    {j | ∃ hj, ∃ N, (raiseRaise hγ S T ρ₂).f j hj = ⟨A, inr N⟩ ∧ a₂ ∈ N} := by
  obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq ha₁
  have ha₁ := raise_injective' ha₁
  have ha₂ := raise_injective' ha₂
  rw [smul_eq_iff_eq_inv_smul] at ha₁ ha₂
  have := ha₂.symm.trans ha₁
  simp only [Allowable.smul_address, map_inv, Tree.inv_apply, smul_inl, Address.mk.injEq,
    inl.injEq, true_and] at this
  rintro j ⟨hj₁, N, hj₂, hN⟩
  obtain ⟨N', hN'⟩ := raiseRaise_f_eq_nearLitter (ρ₂ := ρ₂) j hj₁ _ _ hj₂
  refine ⟨hj₁, N', hN', ?_⟩
  obtain (hj | ⟨hj, hj'⟩ | ⟨hj, hj'⟩) := raiseRaise_cases hj₁
  · rw [raiseRaise_f_eq₁ hj] at hj₂ hN'
    have h₁ := raise_injective' hj₂
    have h₂ := raise_injective' hN'
    rw [smul_eq_iff_eq_inv_smul] at h₁ h₂ this
    simp only [h₁, Allowable.smul_address, map_inv, Tree.inv_apply, smul_inr, Address.mk.injEq,
      inr.injEq, ← smul_eq_iff_eq_inv_smul, true_and] at h₂
    rw [← h₂, this, inv_inv]
    rw [smul_smul, smul_smul, ← NearLitterPerm.NearLitter.mem_snd_iff,
      NearLitterPerm.smul_nearLitter_snd, Set.smul_mem_smul_set_iff,
      NearLitterPerm.NearLitter.mem_snd_iff]
    exact hN
  · rw [raiseRaise_f_eq₂ hj hj'] at hj₂ hN'
    rw [inv_smul_eq_iff] at this
    rw [this]
    cases hN'.symm.trans hj₂
    rw [← NearLitterPerm.NearLitter.mem_snd_iff, ← Set.mem_inv_smul_set_iff,
      ← NearLitterPerm.smul_nearLitter_snd]
    have := hρS ⟨A, inr N⟩ ⟨_, _, hj₂.symm⟩
    simp only [Allowable.smul_address, map_inv, Tree.inv_apply, smul_inr, Address.mk.injEq,
      inr.injEq, true_and] at this
    rw [← this]
    rw [NearLitterPerm.smul_nearLitter_snd, Set.smul_mem_smul_set_iff]
    exact hN
  · rw [raiseRaise_f_eq₃ hj (by exact hj')] at hj₂ hN'
    have h₁ := raise_injective' hj₂
    have h₂ := raise_injective' hN'
    rw [smul_eq_iff_eq_inv_smul] at h₁ h₂ this
    simp only [h₁, Allowable.smul_address, map_inv, Tree.inv_apply, smul_inr, Address.mk.injEq,
      inr.injEq, ← smul_eq_iff_eq_inv_smul, true_and] at h₂
    rw [← h₂, this, inv_inv]
    rw [smul_smul, smul_smul, ← NearLitterPerm.NearLitter.mem_snd_iff,
      NearLitterPerm.smul_nearLitter_snd, Set.smul_mem_smul_set_iff,
      NearLitterPerm.NearLitter.mem_snd_iff]
    exact hN

theorem raiseRaise_atom_spec₂
    (hρS : ∀ c : Address β, raise iβ.elim c ∈ S → ρ₁⁻¹ • c = ρ₂⁻¹ • c)
    {i : κ} {hi : i < (raiseRaise hγ S T ρ₁).max}
    {A : ExtendedIndex α} {a₁ a₂ : Atom}
    (ha₁ : (raiseRaise hγ S T ρ₁).f i hi = ⟨A, inl a₁⟩)
    (ha₂ : (raiseRaise hγ S T ρ₂).f i hi = ⟨A, inl a₂⟩) :
    {j | ∃ hj, ∃ N, (raiseRaise hγ S T ρ₁).f j hj = ⟨A, inr N⟩ ∧ a₁ ∈ N} ⊆
    {j | ∃ hj, ∃ N, (raiseRaise hγ S T ρ₂).f j hj = ⟨A, inr N⟩ ∧ a₂ ∈ N} := by
  obtain (hi | ⟨hi, hi'⟩ | ⟨hi, hi'⟩) := raiseRaise_cases hi
  · rw [raiseRaise_f_eq₁ hi] at ha₁ ha₂
    exact raiseRaise_atom_spec₂_raise hρS ha₁ ha₂
  · rw [raiseRaise_f_eq₂ hi hi'] at ha₁ ha₂
    have := ha₁.symm.trans ha₂
    simp only [Address.mk.injEq, inl.injEq, true_and] at this
    subst this
    rintro j ⟨hj₁, N, hj₂, hN⟩
    refine ⟨hj₁, ?_⟩
    obtain (hj | ⟨hj, hj'⟩ | ⟨hj, hj'⟩) := raiseRaise_cases hj₁
    · rw [raiseRaise_f_eq₁ hj] at hj₂ ⊢
      obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq hj₂
      have hj₂ := raise_injective' hj₂
      rw [smul_eq_iff_eq_inv_smul] at hj₂
      rw [hj₂]
      refine ⟨Allowable.toStructPerm (ρ₂ * ρ₁⁻¹) A • N, ?_, ?_⟩
      · simp only [Allowable.smul_address, map_inv, Tree.inv_apply, smul_inr, raise, map_mul,
          Tree.mul_apply, mul_smul]
      · change _ = raise iβ.elim ⟨A, inl a₁⟩ at ha₁
        have := hρS _ ⟨_, _, ha₁.symm⟩
        simp only [Allowable.smul_address_eq_smul_iff, map_inv, Tree.inv_apply, smul_inl,
          inl.injEq] at this
        rw [map_mul, map_inv, Tree.mul_apply, Tree.inv_apply, mul_smul,
          ← NearLitterPerm.NearLitter.mem_snd_iff,
          NearLitterPerm.smul_nearLitter_snd, Set.mem_smul_set_iff_inv_smul_mem,
          ← this, NearLitterPerm.smul_nearLitter_snd, Set.smul_mem_smul_set_iff]
        exact hN
    · rw [raiseRaise_f_eq₂ hj hj'] at hj₂ ⊢
      exact ⟨N, hj₂, hN⟩
    · rw [raiseRaise_f_eq₃ hj (by exact hj')] at hj₂ ⊢
      obtain ⟨A, rfl⟩ := raiseIndex_of_raise_eq hj₂
      have hj₂ := raise_injective' hj₂
      rw [smul_eq_iff_eq_inv_smul] at hj₂
      rw [hj₂]
      refine ⟨Allowable.toStructPerm (ρ₂ * ρ₁⁻¹) A • N, ?_, ?_⟩
      · simp only [Allowable.smul_address, map_inv, Tree.inv_apply, smul_inr, raise, map_mul,
          Tree.mul_apply, mul_smul]
      · change _ = raise iβ.elim ⟨A, inl a₁⟩ at ha₁
        have := hρS _ ⟨_, _, ha₁.symm⟩
        simp only [Allowable.smul_address_eq_smul_iff, map_inv, Tree.inv_apply, smul_inl,
          inl.injEq] at this
        rw [map_mul, map_inv, Tree.mul_apply, Tree.inv_apply, mul_smul,
          ← NearLitterPerm.NearLitter.mem_snd_iff,
          NearLitterPerm.smul_nearLitter_snd, Set.mem_smul_set_iff_inv_smul_mem,
          ← this, NearLitterPerm.smul_nearLitter_snd, Set.smul_mem_smul_set_iff]
        exact hN
  · rw [raiseRaise_f_eq₃ hi (by exact hi')] at ha₁ ha₂
    exact raiseRaise_atom_spec₂_raise hρS ha₁ ha₂

theorem raiseRaise_inflexibleCoe_spec₂_comp_before
    (hρS : ∀ c : Address β, raise iβ.elim c ∈ S → ρ₁⁻¹ • c = ρ₂⁻¹ • c)
    {i : κ} (hi : i < (raiseRaise hγ S T ρ₁).max) (hi' : (interferenceSupport hγ S T).max ≤ i)
    (hi'' : i < (interferenceSupport hγ S T).max + S.max)
    {A : ExtendedIndex α} {N : NearLitter} (h : InflexibleCoe A N.1)
    (hN : S.f (i - (interferenceSupport hγ S T).max) (κ_sub_lt hi'' hi') = ⟨A, inr N⟩) :
    ∃ ρ : Allowable h.path.δ,
    ρ • ((raiseRaise hγ S T ρ₁).before i hi).comp (h.path.B.cons h.path.hδ) =
    ((raiseRaise hγ S T ρ₂).before i hi).comp (h.path.B.cons h.path.hδ) ∧
    ρ • h.t.set = h.t.set := by
  by_cases hA : ∃ B, (h.path.B.cons h.path.hδ) = (Hom.toPath iβ.elim).comp B
  · obtain ⟨B, hB⟩ := hA
    rw [hB]
    refine ⟨Allowable.comp B (ρ₂ * ρ₁⁻¹), ?_⟩
    letI : LeLevel α := ⟨le_rfl⟩
    rw [comp_comp, comp_comp, ← comp_smul]
  · sorry

theorem raiseRaise_specifies (S : Support α) (hS : S.Strong) (T : Support γ) (ρ : Allowable β)
    (hρS : ∀ c : Address β, raise iβ.elim c ∈ S → ρ • c = c) {σ : Spec α}
    (hσ : σ.Specifies (raiseRaise hγ S T 1) (raiseRaise_strong hS (fun c _ => by rw [one_smul]))) :
    σ.Specifies (raiseRaise hγ S T ρ) (raiseRaise_strong hS hρS) where
  max_eq_max := raiseRaise_max_eq_max.symm.trans hσ.max_eq_max
  atom_spec := by
    intro i hi A a ha
    obtain ⟨b, hb⟩ := raiseRaise_f_eq_atom (ρ₂ := 1) i hi A a ha
    rw [hσ.atom_spec i hi A b hb, SpecCondition.atom.injEq]
    refine ⟨rfl, ?_, ?_⟩
    · refine subset_antisymm ?_ ?_
      · refine raiseRaise_atom_spec₁ ?_ hb ha
        intro c hc
        rw [one_smul, hρS]
        rwa [one_smul] at hc
      · refine raiseRaise_atom_spec₁ ?_ ha hb
        intro c hc
        have := hρS (ρ • c) hc
        rw [smul_left_cancel_iff] at this
        rwa [one_smul]
    · refine subset_antisymm ?_ ?_
      · refine raiseRaise_atom_spec₂ ?_ hb ha
        intro c hc
        rw [inv_one, one_smul, eq_inv_smul_iff]
        exact hρS c hc
      · refine raiseRaise_atom_spec₂ ?_ ha hb
        intro c hc
        rw [inv_one, one_smul, inv_smul_eq_iff]
        exact (hρS c hc).symm
  flexible_spec := sorry
  inflexibleCoe_spec := by
    intro i hi A N₁ h hN₁
    obtain ⟨N₂, hN₂⟩ := raiseRaise_f_eq_nearLitter (ρ₂ := 1) i hi A N₁ hN₁
    obtain (⟨hi', hi''⟩ | ⟨hi, hi', A, rfl⟩) := raiseRaise_cases_nearLitter hN₁ hN₂
    · have : N₁ = N₂
      · rw [raiseRaise_f_eq₂ hi' hi''] at hN₁ hN₂
        cases hN₁.symm.trans hN₂
        rfl
      cases this
      rw [hσ.inflexibleCoe_spec i hi A N₁ h hN₂]
      rw [raiseRaise_f_eq₂ hi' hi''] at hN₁ hN₂
      simp only [Tangle.coe_set, Tangle.coe_support, SpecCondition.inflexibleCoe.injEq, heq_eq_eq,
        CodingFunction.code_eq_code_iff, true_and]
      refine ⟨?_, ?_, ?_⟩
    · obtain ⟨P, t, hN₁', hN₂'⟩ := raiseRaise_inflexibleCoe₃ hi hi' hN₁ hN₂ h
      sorry
  inflexibleBot_spec := sorry

end ConNF.Support
