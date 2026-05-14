Config = Config or {}

-- Core settings. Keep this file as the main place server owners edit behavior.
Config.Framework = 'qb' -- qb, standalone. ESX scaffold exists but is intentionally not active yet.
Config.Inventory = 'auto' -- auto, ox_inventory, qb-inventory, none
Config.UseOxLib = true
Config.Debug = false
Config.Locale = 'en'

Config.ItemRequirements = {
    Enabled = true,
    ConsumeOnSuccess = true,
    ConsumeOnPartial = true,
    ConsumeOnFail = false,
    ConsumeOnWorsen = true
}

Config.Targeting = {
    MaxPatientDistance = 3.0,
    StretcherDistance = 4.0
}

Config.DeathSystem = {
    Enabled = true,
    DisableAutoRespawn = true,
    BleedoutSeconds = {
        incapacitated = 900,
        unconscious = 720,
        critical = 420,
        cardiac_arrest = 300
    },
    ReviveRequiresStable = true,
    RespawnAllowedAtDeceased = true
}

Config.Progression = {
    Enabled = true,
    TickMs = 30000,
    SaveIntervalMs = 120000,
    MinorBleedWorsenMinutes = 10,
    ModerateBleedWorsenMinutes = 6,
    SevereBleedShockMinutes = 3,
    LowOxygenArrestMinutes = 4,
    ShockArrestMinutes = 5,
    UntreatedComplicationChance = 8
}

Config.AutomatedRecovery = {
    Enabled = true,
    RequireHospital = true,
    StabilizationImprovesChance = true,
    BaseChance = 72,
    StableBonus = 16,
    CriticalPenalty = 25,
    SurgeryScaffoldOnly = true, -- Future doctor/surgeon expansion can attach here.
    ScanDurationSeconds = 20,
    TreatmentDurationSeconds = 45,
    Locations = {
        {
            id = 'pillbox',
            label = 'Pillbox Medical Center',
            coords = vector3(298.6, -584.6, 43.3),
            radius = 55.0,
            beds = {
                vector4(307.7, -581.0, 44.2, 160.0),
                vector4(309.3, -577.8, 44.2, 160.0),
                vector4(313.8, -579.0, 44.2, 160.0)
            }
        }
    }
}

Config.BodyParts = {
    head = { label = 'Head', vital = true },
    neck = { label = 'Neck', vital = true },
    chest = { label = 'Chest', vital = true },
    abdomen = { label = 'Abdomen', vital = true },
    left_arm = { label = 'Left Arm', vital = false },
    right_arm = { label = 'Right Arm', vital = false },
    left_leg = { label = 'Left Leg', vital = false },
    right_leg = { label = 'Right Leg', vital = false },
    spine = { label = 'Spine / Back', vital = true }
}

Config.BoneMap = {
    [31086] = 'head',
    [12844] = 'head',
    [39317] = 'neck',
    [24816] = 'spine',
    [24817] = 'spine',
    [24818] = 'spine',
    [24806] = 'abdomen',
    [11816] = 'abdomen',
    [57597] = 'spine',
    [64729] = 'left_arm',
    [45509] = 'left_arm',
    [61163] = 'left_arm',
    [18905] = 'left_arm',
    [10706] = 'right_arm',
    [40269] = 'right_arm',
    [28252] = 'right_arm',
    [57005] = 'right_arm',
    [58271] = 'left_leg',
    [63931] = 'left_leg',
    [2108] = 'left_leg',
    [51826] = 'right_leg',
    [36864] = 'right_leg',
    [20781] = 'right_leg'
}

Config.Jobs = {
    civilian = { role = 'civilian', label = 'Civilian', rankBonus = 0 },
    police = { role = 'police', label = 'Police Officer', rankBonus = 2 },
    sheriff = { role = 'police', label = 'Sheriff Deputy', rankBonus = 2 },
    ambulance = { role = 'ems', label = 'EMS', rankBonus = 4 },
    fire = { role = 'fire', label = 'Firefighter', rankBonus = 3 },
    hospital = { role = 'hospital_staff', label = 'Hospital Staff', rankBonus = 4 },
    coroner = { role = 'coroner', label = 'Coroner', rankBonus = 2 }
}

Config.Certifications = {
    basic_first_aid = { label = 'Basic First Aid', level = 1 },
    cpr = { label = 'CPR', level = 1 },
    aed = { label = 'AED', level = 2 },
    bleeding_control = { label = 'Bleeding Control', level = 2 },
    narcan = { label = 'Narcan', level = 2 },
    oxygen = { label = 'Oxygen Support', level = 3 },
    trauma = { label = 'Trauma Care', level = 3 },
    emtb = { label = 'EMT-B', level = 4 },
    emta = { label = 'EMT-A', level = 5 },
    paramedic = { label = 'Paramedic', level = 6 },
    flight_medic = { label = 'Flight Medic', level = 7 },
    hospital_recovery = { label = 'Automated Hospital Recovery', level = 5 },
    coroner = { label = 'Medical Examiner', level = 3 }
}

Config.RoleDefaults = {
    civilian = { 'basic_first_aid' },
    police = { 'basic_first_aid', 'cpr', 'aed', 'bleeding_control', 'narcan' },
    fire = { 'basic_first_aid', 'cpr', 'aed', 'bleeding_control', 'oxygen', 'trauma' },
    ems = { 'basic_first_aid', 'cpr', 'aed', 'bleeding_control', 'narcan', 'oxygen', 'trauma', 'emtb' },
    hospital_staff = { 'basic_first_aid', 'cpr', 'aed', 'oxygen', 'trauma', 'hospital_recovery' },
    coroner = { 'basic_first_aid', 'coroner' }
}

Config.AssessmentTools = {
    check_pulse = { label = 'Check Pulse', time = 2500, allowedRoles = { 'civilian', 'police', 'fire', 'ems', 'hospital_staff', 'coroner' }, cert = nil },
    check_breathing = { label = 'Check Breathing', time = 2500, allowedRoles = { 'civilian', 'police', 'fire', 'ems', 'hospital_staff', 'coroner' }, cert = nil },
    blood_pressure = { label = 'Blood Pressure', time = 5000, allowedRoles = { 'ems', 'hospital_staff' }, cert = 'emtb' },
    oxygen_saturation = { label = 'Oxygen Saturation', time = 3500, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, cert = 'oxygen' },
    blood_glucose = { label = 'Blood Glucose', time = 4000, allowedRoles = { 'ems', 'hospital_staff' }, cert = 'emta' },
    pupils = { label = 'Check Pupils', time = 3000, allowedRoles = { 'police', 'fire', 'ems', 'hospital_staff', 'coroner' }, cert = 'basic_first_aid' },
    responsiveness = { label = 'Responsiveness', time = 2500, allowedRoles = { 'civilian', 'police', 'fire', 'ems', 'hospital_staff', 'coroner' }, cert = nil },
    full_body_scan = { label = 'Full Body Scan', time = 10000, allowedRoles = { 'ems', 'hospital_staff', 'coroner' }, cert = 'trauma' },
    trauma_assessment = { label = 'Trauma Assessment', time = 8000, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, cert = 'trauma' },
    vitals_monitor = { label = 'Vitals Monitor', time = 5000, allowedRoles = { 'ems', 'hospital_staff' }, cert = 'emtb' }
}

Config.Treatments = {
    gloves = { label = 'Put On Gloves', item = 'med_gloves', time = 1000, allowedRoles = { 'civilian', 'police', 'fire', 'ems', 'hospital_staff', 'coroner' }, requiredCert = nil, target = 'provider', baseSuccess = 100 },
    bandage = { label = 'Bandage', item = 'bandage', time = 5000, allowedRoles = { 'civilian', 'police', 'fire', 'ems', 'hospital_staff' }, requiredCert = 'basic_first_aid', treats = { 'external_bleeding', 'minor_cut', 'stab_wound' }, bodyParts = 'all', baseSuccess = 55, effect = { bleeding = -1, pain = -5 } },
    gauze = { label = 'Pack Wound With Gauze', item = 'med_gauze', time = 6500, allowedRoles = { 'police', 'fire', 'ems', 'hospital_staff' }, requiredCert = 'bleeding_control', treats = { 'external_bleeding', 'gunshot_wound', 'stab_wound' }, bodyParts = 'all', baseSuccess = 62, effect = { bleeding = -1, pain = 2 } },
    hemostatic_gauze = { label = 'Hemostatic Gauze', item = 'hemostatic_gauze', time = 7000, allowedRoles = { 'police', 'fire', 'ems', 'hospital_staff' }, requiredCert = 'bleeding_control', treats = { 'gunshot_wound', 'stab_wound', 'external_bleeding' }, bodyParts = 'all', baseSuccess = 78, effect = { bleeding = -2, pain = 4 } },
    pressure_dressing = { label = 'Pressure Dressing', item = 'pressure_dressing', time = 6500, allowedRoles = { 'police', 'fire', 'ems', 'hospital_staff' }, requiredCert = 'bleeding_control', treats = { 'external_bleeding', 'gunshot_wound', 'stab_wound' }, bodyParts = 'all', baseSuccess = 74, effect = { bleeding = -2, pain = 1 } },
    tourniquet = { label = 'Tourniquet', item = 'tourniquet', time = 6000, allowedRoles = { 'police', 'fire', 'ems', 'hospital_staff' }, requiredCert = 'bleeding_control', treats = { 'gunshot_wound', 'stab_wound', 'external_bleeding', 'amputation' }, bodyParts = { 'left_arm', 'right_arm', 'left_leg', 'right_leg' }, baseSuccess = 70, effect = { bleeding = -3, pain = 8 } },
    chest_seal = { label = 'Chest Seal', item = 'chest_seal', time = 6000, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, requiredCert = 'trauma', treats = { 'gunshot_wound', 'stab_wound', 'chest_trauma' }, bodyParts = { 'chest' }, baseSuccess = 76, effect = { bleeding = -1, oxygen = 8 } },
    splint = { label = 'Splint', item = 'splint', time = 8000, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, requiredCert = 'trauma', treats = { 'broken_bone', 'sprain' }, bodyParts = { 'left_arm', 'right_arm', 'left_leg', 'right_leg' }, baseSuccess = 80, effect = { pain = -18, immobilize = true } },
    neck_brace = { label = 'Neck Brace', item = 'neck_brace', time = 7000, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, requiredCert = 'trauma', treats = { 'head_trauma', 'spinal_injury', 'blunt_trauma' }, bodyParts = { 'head', 'neck', 'spine' }, baseSuccess = 78, effect = { pain = -10, stabilize = true } },
    backboard = { label = 'Backboard', item = 'backboard', time = 9000, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, requiredCert = 'trauma', treats = { 'spinal_injury', 'blunt_trauma', 'vehicle_trauma', 'fall_trauma' }, bodyParts = { 'spine', 'neck', 'head' }, baseSuccess = 82, effect = { pain = -10, stabilize = true } },
    burn_dressing = { label = 'Burn Dressing', item = 'burn_dressing', time = 6500, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, requiredCert = 'basic_first_aid', treats = { 'burn' }, bodyParts = 'all', baseSuccess = 75, effect = { pain = -15, bleeding = -1 } },
    oxygen_mask = { label = 'Oxygen Mask', item = 'oxygen_mask', time = 5000, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, requiredCert = 'oxygen', treats = { 'smoke_inhalation', 'low_oxygen', 'shock' }, bodyParts = { 'head', 'neck', 'chest' }, baseSuccess = 86, effect = { oxygen = 14 } },
    bvm = { label = 'BVM Ventilation', item = 'bvm', time = 7000, allowedRoles = { 'fire', 'ems', 'hospital_staff' }, requiredCert = 'oxygen', treats = { 'respiratory_arrest', 'low_oxygen', 'smoke_inhalation' }, bodyParts = { 'head', 'neck', 'chest' }, baseSuccess = 78, effect = { oxygen = 20 } },
    aed = { label = 'AED', item = 'aed', time = 10000, allowedRoles = { 'police', 'fire', 'ems', 'hospital_staff' }, requiredCert = 'aed', treats = { 'cardiac_arrest' }, bodyParts = { 'chest' }, baseSuccess = 58, effect = { arrest = -1 } },
    defibrillator = { label = 'Defibrillator', item = 'defibrillator', time = 10000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'paramedic', treats = { 'cardiac_arrest' }, bodyParts = { 'chest' }, baseSuccess = 74, effect = { arrest = -1 } },
    iv_kit = { label = 'Start IV', item = 'iv_kit', time = 9000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'emta', treats = { 'shock', 'blood_loss', 'dehydration' }, bodyParts = { 'left_arm', 'right_arm' }, baseSuccess = 76, effect = { shock = -1 } },
    saline = { label = 'Saline', item = 'saline', time = 7000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'emta', treats = { 'shock', 'blood_loss' }, bodyParts = { 'left_arm', 'right_arm' }, baseSuccess = 82, effect = { bloodVolume = 8, shock = -1 } },
    blood_bag = { label = 'Blood Bag', item = 'blood_bag', time = 10000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'paramedic', treats = { 'blood_loss', 'shock' }, bodyParts = { 'left_arm', 'right_arm' }, baseSuccess = 78, effect = { bloodVolume = 18, shock = -1 } },
    pain_medication = { label = 'Pain Medication', item = 'pain_medication', time = 4000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'emta', treats = { 'pain' }, bodyParts = 'all', baseSuccess = 88, effect = { pain = -28 } },
    epinephrine = { label = 'Epinephrine', item = 'epinephrine', time = 4500, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'paramedic', treats = { 'cardiac_arrest', 'shock' }, bodyParts = { 'left_arm', 'right_arm', 'chest' }, baseSuccess = 62, effect = { heartRate = 14, shock = -1 } },
    narcan = { label = 'Narcan', item = 'narcan', time = 4500, allowedRoles = { 'police', 'fire', 'ems', 'hospital_staff' }, requiredCert = 'narcan', treats = { 'overdose', 'respiratory_depression' }, bodyParts = { 'head', 'left_arm', 'right_arm' }, baseSuccess = 84, effect = { oxygen = 10, consciousness = 8 } },
    trauma_kit = { label = 'Trauma Kit', item = 'trauma_kit', time = 12000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'trauma', treats = { 'gunshot_wound', 'stab_wound', 'blunt_trauma', 'vehicle_trauma', 'fall_trauma', 'explosion_trauma' }, bodyParts = 'all', baseSuccess = 84, effect = { bleeding = -2, pain = -12, stabilize = true } },
    hospital_bed = { label = 'Automated Bed Recovery', item = nil, time = 45000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'hospital_recovery', treats = { 'all' }, bodyParts = 'all', baseSuccess = 92, hospitalOnly = true, effect = { automatedRecovery = true } },
    xray = { label = 'X-Ray Scan', item = nil, time = 20000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'hospital_recovery', treats = { 'broken_bone', 'blunt_trauma', 'vehicle_trauma', 'fall_trauma' }, bodyParts = 'all', baseSuccess = 95, hospitalOnly = true, effect = { scan = true } },
    ct_scan = { label = 'CT Scan', item = nil, time = 30000, allowedRoles = { 'ems', 'hospital_staff' }, requiredCert = 'hospital_recovery', treats = { 'head_trauma', 'internal_bleeding', 'spinal_injury' }, bodyParts = 'all', baseSuccess = 95, hospitalOnly = true, effect = { scan = true } }
}

Config.RoleSuccessOverrides = {
    tourniquet = {
        civilian = 35,
        police = 70,
        fire = 80,
        ems = 88,
        hospital_staff = 93
    },
    aed = {
        police = 70,
        fire = 76,
        ems = 84,
        hospital_staff = 88
    }
}

Config.SuccessTuning = {
    CertLevelBonus = 4,
    MissingCertPenalty = 28,
    WrongRolePenalty = 40,
    SeverityPenalty = 7,
    MovementPenalty = 15,
    UntreatedMinutePenalty = 1.2,
    CorrectToolBonus = 8,
    HospitalBonus = 14,
    StabilizedBonus = 8,
    MinChance = 5,
    MaxChance = 98,
    PartialWithin = 18,
    WorsenBelow = 12
}

Config.InjuryProfiles = {
    gunshot_wound = { label = 'Gunshot Wound', bleeding = 2, pain = 45, consciousness = 8, oxygen = 0, worsenRisk = 18, complications = { 'internal_bleeding', 'shock', 'infection' } },
    stab_wound = { label = 'Stab Wound', bleeding = 2, pain = 38, consciousness = 4, oxygen = 0, worsenRisk = 15, complications = { 'internal_bleeding', 'shock', 'infection' } },
    blunt_trauma = { label = 'Blunt Trauma', bleeding = 0, pain = 28, consciousness = 8, oxygen = 0, worsenRisk = 9, complications = { 'broken_bone', 'internal_bleeding' } },
    burn = { label = 'Burn', bleeding = 0, pain = 40, consciousness = 2, oxygen = -4, worsenRisk = 11, complications = { 'shock', 'infection' } },
    smoke_inhalation = { label = 'Smoke Inhalation', bleeding = 0, pain = 12, consciousness = 12, oxygen = -18, worsenRisk = 20, complications = { 'low_oxygen', 'respiratory_arrest' } },
    broken_bone = { label = 'Broken Bone', bleeding = 0, pain = 35, consciousness = 0, oxygen = 0, worsenRisk = 6, complications = { 'shock' } },
    sprain = { label = 'Sprain', bleeding = 0, pain = 18, consciousness = 0, oxygen = 0, worsenRisk = 3, complications = {} },
    internal_bleeding = { label = 'Internal Bleeding', bleeding = 2, pain = 34, consciousness = 8, oxygen = -4, worsenRisk = 24, complications = { 'shock', 'cardiac_arrest' } },
    external_bleeding = { label = 'External Bleeding', bleeding = 2, pain = 20, consciousness = 4, oxygen = 0, worsenRisk = 18, complications = { 'blood_loss', 'shock' } },
    head_trauma = { label = 'Head Trauma', bleeding = 0, pain = 42, consciousness = 24, oxygen = 0, worsenRisk = 17, complications = { 'unconsciousness', 'low_oxygen' } },
    spinal_injury = { label = 'Spinal Injury', bleeding = 0, pain = 50, consciousness = 8, oxygen = 0, worsenRisk = 12, complications = { 'shock' } },
    chest_trauma = { label = 'Chest Trauma', bleeding = 1, pain = 44, consciousness = 10, oxygen = -14, worsenRisk = 22, complications = { 'low_oxygen', 'shock' } },
    low_oxygen = { label = 'Low Oxygen', bleeding = 0, pain = 8, consciousness = 20, oxygen = -25, worsenRisk = 28, complications = { 'unconsciousness', 'cardiac_arrest' } },
    shock = { label = 'Shock', bleeding = 0, pain = 12, consciousness = 18, oxygen = -8, worsenRisk = 26, complications = { 'cardiac_arrest' } },
    cardiac_arrest = { label = 'Cardiac Arrest', bleeding = 0, pain = 0, consciousness = 100, oxygen = -70, worsenRisk = 35, complications = { 'deceased' } },
    vehicle_trauma = { label = 'Vehicle Crash Trauma', bleeding = 1, pain = 38, consciousness = 12, oxygen = -4, worsenRisk = 18, complications = { 'broken_bone', 'internal_bleeding', 'spinal_injury' } },
    fall_trauma = { label = 'Fall Trauma', bleeding = 1, pain = 36, consciousness = 12, oxygen = 0, worsenRisk = 15, complications = { 'broken_bone', 'head_trauma', 'spinal_injury' } },
    explosion_trauma = { label = 'Explosion Trauma', bleeding = 2, pain = 52, consciousness = 20, oxygen = -12, worsenRisk = 28, complications = { 'burn', 'internal_bleeding', 'low_oxygen' } },
    overdose = { label = 'Overdose', bleeding = 0, pain = 5, consciousness = 35, oxygen = -24, worsenRisk = 22, complications = { 'respiratory_depression', 'cardiac_arrest' } },
    respiratory_depression = { label = 'Respiratory Depression', bleeding = 0, pain = 4, consciousness = 24, oxygen = -25, worsenRisk = 24, complications = { 'respiratory_arrest' } },
    respiratory_arrest = { label = 'Respiratory Arrest', bleeding = 0, pain = 0, consciousness = 90, oxygen = -65, worsenRisk = 32, complications = { 'cardiac_arrest' } },
    blood_loss = { label = 'Blood Loss', bleeding = 0, pain = 6, consciousness = 20, oxygen = -8, worsenRisk = 22, complications = { 'shock' } },
    pain = { label = 'Severe Pain', bleeding = 0, pain = 55, consciousness = 4, oxygen = 0, worsenRisk = 4, complications = { 'shock' } }
}

Config.DamageMap = {
    firearm = 'gunshot_wound',
    melee = 'stab_wound',
    unarmed = 'blunt_trauma',
    vehicle = 'vehicle_trauma',
    fall = 'fall_trauma',
    explosion = 'explosion_trauma',
    fire = 'burn',
    smoke = 'smoke_inhalation',
    generic = 'blunt_trauma'
}

Config.Severity = {
    minor = { score = 1, label = 'Minor', minDamage = 1, maxDamage = 12 },
    moderate = { score = 2, label = 'Moderate', minDamage = 13, maxDamage = 29 },
    severe = { score = 3, label = 'Severe', minDamage = 30, maxDamage = 54 },
    critical = { score = 4, label = 'Critical', minDamage = 55, maxDamage = 999 }
}

Config.HospitalActions = {
    admit = { label = 'Admit Patient', roles = { 'ems', 'hospital_staff' } },
    triage = { label = 'Triage Patient', roles = { 'ems', 'hospital_staff' } },
    assign_bed = { label = 'Assign Bed', roles = { 'ems', 'hospital_staff' } },
    scan = { label = 'Perform Scan', roles = { 'ems', 'hospital_staff' } },
    automated_recovery = { label = 'Automated Recovery', roles = { 'ems', 'hospital_staff' } },
    discharge = { label = 'Discharge Patient', roles = { 'ems', 'hospital_staff' } },
    history = { label = 'View Medical History', roles = { 'ems', 'hospital_staff', 'coroner' } }
}

Config.Report = {
    RequireJob = false,
    AllowedRoles = { 'police', 'fire', 'ems', 'hospital_staff', 'coroner' },
    MaxNarrativeLength = 2000
}

Config.Admin = {
    AcePermission = 'srp_medical.admin',
    AllowConsole = true
}

